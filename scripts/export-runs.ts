import { parsePersona, type Persona } from "../data/schema.ts";
import { buildRunBundle } from "../supabase/functions/_shared/engine/cards.ts";

export function sortKeys(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(sortKeys);
  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    return Object.fromEntries(Object.keys(record).sort().map((key) => [key, sortKeys(record[key])]));
  }
  return value;
}

export function bundleText(persona: Persona, profile: { handle: string; is_teen: boolean }) {
  return `${JSON.stringify(sortKeys(buildRunBundle(persona, profile)), null, 2)}\n`;
}

const root = new URL("../", import.meta.url);

async function load(key: string) {
  const text = await Deno.readTextFile(new URL(`data/personas/${key}.json`, root));
  return parsePersona(JSON.parse(text));
}

if (import.meta.main) {
  const maya = await load("maya");
  const jobs: [string, Persona, { handle: string; is_teen: boolean }][] = [
    ["maya", maya, { handle: maya.profile.handle, is_teen: false }],
    ["maya-teen", maya, { handle: maya.profile.handle, is_teen: true }],
  ];
  for (const key of ["ghost", "emerging", "established"]) {
    const persona = await load(key);
    jobs.push([key, persona, { handle: persona.profile.handle, is_teen: persona.profile.is_teen }]);
  }
  const out = new URL("ios/IGWrapped/Resources/Runs/", root);
  await Deno.mkdir(out, { recursive: true });
  for (const [name, persona, profile] of jobs) {
    await Deno.writeTextFile(new URL(`${name}.json`, out), bundleText(persona, profile));
  }
}
