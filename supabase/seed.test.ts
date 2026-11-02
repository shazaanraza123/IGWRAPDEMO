import { loadPersonas, renderSeedSql } from "./seed.ts";

Deno.test("seed sql matches the persona files and the committed seed", async () => {
  const personas = await loadPersonas();
  const sql = renderSeedSql(personas);
  const committed = await Deno.readTextFile(new URL("./seed.sql", import.meta.url));
  if (sql !== committed) {
    throw new Error("supabase/seed.sql is stale. Run: deno run --allow-read --allow-write supabase/seed.ts");
  }

  for (const key of ["maya", "ghost", "connector", "emerging", "established", "teen"]) {
    if (!sql.includes(`'${key}'`)) throw new Error(`seed is missing ${key}`);
  }

  const ghost = sql.split("$persona_ghost$")[1];
  if (!ghost || ghost.includes('"totals"')) throw new Error("ghost seed invented totals");
  const maya = sql.split("$persona_maya$")[1];
  if (!maya.includes('"posts":38')) throw new Error("maya posts are not 38");
  if (!sql.includes("'maya.lens'") || !sql.includes("'maya.teen'")) {
    throw new Error("maya and teen handles missing");
  }
  if (!sql.includes("'post_0719'") || !sql.includes("'story_0314'")) {
    throw new Error("maya's real post and story were not seeded");
  }
});
