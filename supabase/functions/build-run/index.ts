import { buildPersonalRun, DEFAULT_PRIVACY, type PrivacySettings, type RunSource } from "../_shared/engine/cards.ts";
import { persistRun } from "../_shared/engine/persist.ts";

type ProfileRow = {
  id: string;
  handle: string;
  is_teen: boolean;
  source_document: RunSource | null;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "POST only" }, 405);
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) return json({ error: "missing function env" }, 500);

  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "") ?? "";
  if (!token) return json({ error: "missing authorization" }, 401);

  let userId = "";
  if (token === serviceRoleKey) {
    const body = await req.json().catch(() => ({}));
    userId = typeof body.user_id === "string" ? body.user_id : "";
  } else {
    const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: { apikey: serviceRoleKey, Authorization: `Bearer ${token}` },
    });
    if (!userResponse.ok) return json({ error: "invalid session" }, 401);
    const user = await userResponse.json();
    userId = typeof user.id === "string" ? user.id : "";
  }
  if (!userId) return json({ error: "missing user" }, 400);

  const profileResponse = await fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${userId}&select=*`, {
    headers: { apikey: serviceRoleKey, Authorization: `Bearer ${serviceRoleKey}` },
  });
  if (!profileResponse.ok) return json({ error: "profile lookup failed" }, 500);
  const profiles = await profileResponse.json() as ProfileRow[];
  const profile = profiles[0];
  if (!profile?.source_document) return json({ error: "persona source missing" }, 400);

  const privacyResponse = await fetch(`${supabaseUrl}/rest/v1/privacy_settings?user_id=eq.${userId}&select=*`, {
    headers: { apikey: serviceRoleKey, Authorization: `Bearer ${serviceRoleKey}` },
  });
  const privacyRows = privacyResponse.ok ? await privacyResponse.json() as PrivacySettings[] : [];
  const privacy = { ...DEFAULT_PRIVACY, ...privacyRows[0] };
  const run = buildPersonalRun(profile.source_document, { handle: profile.handle, is_teen: profile.is_teen }, privacy);
  const runId = await persistRun(supabaseUrl, serviceRoleKey, userId, run);
  return json({ run_id: runId, tier: run.tier, cards: run.cards.length });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}
