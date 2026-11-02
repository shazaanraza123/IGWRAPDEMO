import { claimPersona } from "../_shared/engine/claim.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "POST only" }, 405);
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) return json({ error: "missing function env" }, 500);

  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "") ?? "";
  if (!token) return json({ error: "missing authorization" }, 401);
  const userResponse = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { apikey: serviceRoleKey, Authorization: `Bearer ${token}` },
  });
  if (!userResponse.ok) return json({ error: "invalid session" }, 401);
  const user = await userResponse.json();
  const userId = typeof user.id === "string" ? user.id : "";
  if (!userId) return json({ error: "missing user" }, 400);

  const body = await req.json().catch(() => ({}));
  const personaKey = typeof body.persona_key === "string" ? body.persona_key : "";
  try {
    const result = await claimPersona({ supabaseUrl, serviceRoleKey, userId, personaKey });
    return json(result);
  } catch (error) {
    const message = error instanceof Error ? error.message : "claim failed";
    return json({ error: message }, 400);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}
