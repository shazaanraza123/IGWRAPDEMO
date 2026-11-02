import { claimPersona } from "./claim.ts";

const mayaCatalog = "11111111-1111-4111-8111-111111111111";

Deno.test("claiming maya copies her catalog onto the anonymous user and builds a run", async () => {
  const permission = await Deno.permissions.query({ name: "env" });
  if (permission.state !== "granted") return;
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const anon = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !anon || !service) return;

  const signIn = await fetch(`${url}/auth/v1/signup`, {
    method: "POST",
    headers: { apikey: anon, Authorization: `Bearer ${anon}`, "Content-Type": "application/json" },
    body: "{}",
  });
  if (!signIn.ok) throw new Error(`anonymous sign-in failed (${signIn.status}): ${await signIn.text()}`);
  const session = await signIn.json();
  const userId = session.user.id as string;
  const token = session.access_token as string;

  try {
    const claim = await fetch(`${url}/functions/v1/claim-persona`, {
      method: "POST",
      headers: { apikey: anon, Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
      body: JSON.stringify({ persona_key: "maya" }),
    });
    if (!claim.ok) throw new Error(`claim failed (${claim.status}): ${await claim.text()}`);
    const result = await claim.json();
    if (result.tier !== "full" || result.cards !== 13 || result.handle !== "maya.lens") {
      throw new Error(JSON.stringify(result));
    }

    const runs = await fetch(`${url}/rest/v1/wrapped_runs?user_id=eq.${userId}&select=status,tier`, {
      headers: { apikey: service, Authorization: `Bearer ${service}` },
    });
    const rows = await runs.json();
    if (rows[0]?.status !== "ready" || rows[0]?.tier !== "full") throw new Error(JSON.stringify(rows));

    const catalog = await fetch(`${url}/rest/v1/profiles?id=eq.${mayaCatalog}&select=handle`, {
      headers: { apikey: service, Authorization: `Bearer ${service}` },
    });
    const catalogRows = await catalog.json();
    if (catalogRows[0]?.handle !== "catalog.maya") throw new Error("catalog handle moved");

    const again = await fetch(`${url}/auth/v1/token?grant_type=refresh_token`, {
      method: "POST",
      headers: { apikey: anon, Authorization: `Bearer ${anon}`, "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: session.refresh_token }),
    });
    if (!again.ok) throw new Error(`refresh failed: ${await again.text()}`);
    const refreshed = await again.json();
    if (refreshed.user.id !== userId) throw new Error("refresh changed user");
  } finally {
    await fetch(`${url}/auth/v1/admin/users/${userId}`, {
      method: "DELETE",
      headers: { apikey: service, Authorization: `Bearer ${service}` },
    });
  }
});

// Imported so a direct call stays available to the edge function. Referenced to keep the check honest.
void claimPersona;
