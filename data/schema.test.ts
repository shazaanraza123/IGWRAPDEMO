import { CANONICAL_MAYA_TOTALS, parsePersona, type Persona } from "./schema.ts";

const keys = ["maya", "ghost", "connector", "emerging", "established", "teen"] as const;

function assert(condition: unknown, message: string) {
  if (!condition) throw new Error(message);
}

function sameTotals(persona: Persona) {
  const totals = persona.totals;
  if (!totals) throw new Error(`${persona.persona_key} needs totals`);
  for (const [key, value] of Object.entries(CANONICAL_MAYA_TOTALS)) {
    const actual = totals[key as keyof typeof CANONICAL_MAYA_TOTALS];
    if (actual !== value) {
      throw new Error(`${persona.persona_key} ${key} is ${actual}, expected ${value}`);
    }
  }
}

Deno.test("personas match the schema and maya's canonical totals", async () => {
  const personas = new Map<string, Persona>();
  for (const key of keys) {
    const file = new URL(`./personas/${key}.json`, import.meta.url);
    const parsed = parsePersona(JSON.parse(await Deno.readTextFile(file)));
    assert(parsed.persona_key === key, `${key}.json has persona_key ${parsed.persona_key}`);
    personas.set(key, parsed);
  }

  const handles = [...personas.values()].map((persona) => persona.profile.handle);
  assert(new Set(handles).size === handles.length, `handles are not unique: ${handles.join(", ")}`);

  const maya = personas.get("maya");
  const teen = personas.get("teen");
  if (!maya || !teen) throw new Error("maya and teen loaded");
  sameTotals(maya);
  sameTotals(teen);
  assert(maya.profile.is_teen === false, "maya is not a teen");
  assert(teen.profile.is_teen === true, "teen is a teen");
  assert(teen.profile.display_name === maya.profile.display_name, "teen keeps Maya's name");
  assert(teen.profile.handle !== maya.profile.handle, "teen needs her own handle");

  for (const key of ["ghost", "connector", "emerging", "established"] as const) {
    const persona = personas.get(key);
    if (!persona) throw new Error(key);
    assert(persona.totals === undefined, `${key} has totals that were not in the spec`);
    assert(persona.monthly === undefined, `${key} has monthly numbers that were not in the spec`);
    assert(persona.archetypes === undefined, `${key} has archetype scores that were not in the spec`);
  }

  assert(personas.get("emerging")?.profile.account_type === "creator", "emerging is a creator");
  assert(personas.get("established")?.profile.account_type === "creator", "established is a creator");
  assert(personas.get("ghost")?.profile.account_type === "personal", "ghost is a personal account");
  assert(personas.get("connector")?.profile.account_type === "personal", "connector is a personal account");
});
