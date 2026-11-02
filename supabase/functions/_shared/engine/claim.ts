import { buildPersonalRun, DEFAULT_PRIVACY, type PrivacySettings, type RunSource } from "./cards.ts";
import { persistRun, serviceHeaders, serviceRest } from "./persist.ts";

const personaKeys = ["maya", "ghost", "connector", "emerging", "established", "teen"];

type CatalogProfile = {
  id: string;
  handle: string;
  source_document: RunSource & {
    profile: { handle: string; display_name: string; account_type: string; is_teen: boolean; avatar?: string };
  };
};

type ContentRow = {
  id: string;
  kind: string;
  posted_at: string;
  media_path: string | null;
  caption: string | null;
  likes: number | null;
  comments: number | null;
  shares: number | null;
  saves: number | null;
  replies: number | null;
  views: number | null;
};

type EdgeRow = { counterpart_handle: string };

export function catalogHandle(personaKey: string) {
  return `catalog.${personaKey}`;
}

export async function claimPersona(options: {
  supabaseUrl: string;
  serviceRoleKey: string;
  userId: string;
  personaKey: string;
}) {
  const { serviceRoleKey, userId, personaKey } = options;
  const base = options.supabaseUrl.replace(/\/$/, "");
  if (!personaKeys.includes(personaKey)) throw new Error("unknown persona");

  const catalog = await serviceRest(
    base,
    serviceRoleKey,
    `/rest/v1/profiles?handle=eq.${catalogHandle(personaKey)}&select=id,handle,source_document`,
    { headers: serviceHeaders(serviceRoleKey, "return=representation") },
  ) as CatalogProfile[];
  const source = catalog[0];
  if (!source?.source_document) throw new Error("persona catalog missing");

  const document = source.source_document;
  const publicHandle = document.profile.handle;
  const holders = await serviceRest(
    base,
    serviceRoleKey,
    `/rest/v1/profiles?handle=eq.${encodeURIComponent(publicHandle)}&select=id,handle`,
    { headers: serviceHeaders(serviceRoleKey, "return=representation") },
  ) as { id: string; handle: string }[];
  for (const holder of holders) {
    if (holder.id === userId || holder.handle.startsWith("catalog.")) continue;
    await serviceRest(base, serviceRoleKey, `/rest/v1/profiles?id=eq.${holder.id}`, {
      method: "PATCH",
      headers: serviceHeaders(serviceRoleKey, "return=minimal"),
      body: JSON.stringify({ handle: `released.${holder.id}` }),
    });
  }

  const profileBody = {
    id: userId,
    handle: publicHandle,
    display_name: document.profile.display_name,
    avatar_path: document.profile.avatar ?? null,
    account_type: document.profile.account_type,
    is_teen: document.profile.is_teen,
    persona_key: personaKey,
    source_document: document,
  };
  const existing = await serviceRest(
    base,
    serviceRoleKey,
    `/rest/v1/profiles?id=eq.${userId}&select=id`,
    { headers: serviceHeaders(serviceRoleKey, "return=representation") },
  ) as { id: string }[];
  if (existing.length > 0) {
    const { id: _id, ...patch } = profileBody;
    await serviceRest(base, serviceRoleKey, `/rest/v1/profiles?id=eq.${userId}`, {
      method: "PATCH",
      headers: serviceHeaders(serviceRoleKey, "return=minimal"),
      body: JSON.stringify(patch),
    });
    await serviceRest(base, serviceRoleKey, `/rest/v1/content_items?owner_id=eq.${userId}`, {
      method: "DELETE",
      headers: serviceHeaders(serviceRoleKey, "return=minimal"),
    });
    await serviceRest(base, serviceRoleKey, `/rest/v1/interaction_edges?user_id=eq.${userId}`, {
      method: "DELETE",
      headers: serviceHeaders(serviceRoleKey, "return=minimal"),
    });
  } else {
    await serviceRest(base, serviceRoleKey, "/rest/v1/profiles", {
      method: "POST",
      headers: serviceHeaders(serviceRoleKey, "return=minimal"),
      body: JSON.stringify(profileBody),
    });
  }

  const content = await serviceRest(
    base,
    serviceRoleKey,
    `/rest/v1/content_items?owner_id=eq.${source.id}&select=id,kind,posted_at,media_path,caption,likes,comments,shares,saves,replies,views`,
    { headers: serviceHeaders(serviceRoleKey, "return=representation") },
  ) as ContentRow[];
  if (content.length > 0) {
    await serviceRest(base, serviceRoleKey, "/rest/v1/content_items", {
      method: "POST",
      headers: serviceHeaders(serviceRoleKey, "return=minimal"),
      body: JSON.stringify(content.map((item) => ({ ...item, owner_id: userId }))),
    });
  }
  const edges = await serviceRest(
    base,
    serviceRoleKey,
    `/rest/v1/interaction_edges?user_id=eq.${source.id}&select=counterpart_handle`,
    { headers: serviceHeaders(serviceRoleKey, "return=representation") },
  ) as EdgeRow[];
  if (edges.length > 0) {
    await serviceRest(base, serviceRoleKey, "/rest/v1/interaction_edges", {
      method: "POST",
      headers: serviceHeaders(serviceRoleKey, "return=minimal"),
      body: JSON.stringify(edges.map((edge) => ({ user_id: userId, counterpart_handle: edge.counterpart_handle }))),
    });
  }
  const privacyRows = await serviceRest(
    base,
    serviceRoleKey,
    `/rest/v1/privacy_settings?user_id=eq.${userId}&select=user_id`,
    { headers: serviceHeaders(serviceRoleKey, "return=representation") },
  ) as { user_id: string }[];
  if (privacyRows.length === 0) {
    await serviceRest(base, serviceRoleKey, "/rest/v1/privacy_settings", {
      method: "POST",
      headers: serviceHeaders(serviceRoleKey, "return=minimal"),
      body: JSON.stringify({ user_id: userId }),
    });
  }

  const privacy: PrivacySettings = { ...DEFAULT_PRIVACY };
  const run = buildPersonalRun(document, { handle: publicHandle, is_teen: document.profile.is_teen }, privacy);
  const runId = await persistRun(base, serviceRoleKey, userId, run);
  return {
    run_id: runId,
    tier: run.tier,
    cards: run.cards.length,
    display_name: document.profile.display_name,
    handle: publicHandle,
  };
}
