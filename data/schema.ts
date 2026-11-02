import { z } from "npm:zod@3.24.2";

/** Canonical maya totals from docs/05-BACKEND-SCHEMA.md section 5. */
export const CANONICAL_MAYA_TOTALS = {
  posts: 38,
  stories: 412,
  reels_sent: 1206,
  saves: 1214,
  days_active: 301,
  liked_posts: 1840,
  friends_stories_watched_pct: 96,
} as const;

const personaKey = z.enum([
  "maya",
  "ghost",
  "connector",
  "emerging",
  "established",
  "teen",
]);

const dateString = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);

const totalsSchema = z
  .object({
    posts: z.number().int().nonnegative(),
    stories: z.number().int().nonnegative(),
    reels_sent: z.number().int().nonnegative(),
    saves: z.number().int().nonnegative(),
    days_active: z.number().int().nonnegative(),
    liked_posts: z.number().int().nonnegative(),
    friends_stories_watched_pct: z.number().min(0).max(100),
  })
  .strict();

const monthSchema = z
  .object({
    month: z.number().int().min(1).max(12),
    posts: z.number().int().nonnegative(),
    stories: z.number().int().nonnegative(),
    photo: z.string().min(1),
  })
  .strict();

const swatchSchema = z
  .object({
    hex: z.string().regex(/^#[0-9A-Fa-f]{6}$/),
    pct: z.number().nonnegative(),
  })
  .strict();

const topicSchema = z
  .object({
    name: z.string().min(1),
    score: z.number().min(0).max(1),
    cluster: z.string().min(1),
    watched: z.number().int().nonnegative().optional(),
  })
  .strict();

export const personaSchema = z
  .object({
    persona_key: personaKey,
    profile: z
      .object({
        handle: z.string().min(1),
        display_name: z.string().min(1),
        account_type: z.enum(["personal", "creator", "business"]),
        is_teen: z.boolean(),
        city: z.string().min(1).optional(),
        avatar: z.string().min(1).optional(),
      })
      .strict(),
    window: z
      .object({
        start: dateString,
        end: dateString,
        label: z.string().min(1),
      })
      .strict(),
    totals: totalsSchema.optional(),
    monthly: z.array(monthSchema).optional(),
    opening_photos: z.array(z.string().min(1)).optional(),
    feed_color: z
      .object({
        palette_name: z.string().min(1),
        swatches: z.array(swatchSchema).min(1),
      })
      .strict()
      .optional(),
    explore_topics: z.array(topicSchema).optional(),
    reels_categories: z
      .array(
        z
          .object({
            name: z.string().min(1),
            pct: z.number().nonnegative(),
          })
          .strict(),
      )
      .optional(),
    fastest_rising: z
      .object({
        name: z.string().min(1),
        multiple: z.number().positive(),
        since_month: z.number().int().min(1).max(12),
      })
      .strict()
      .optional(),
    ceramics_monthly: z.array(z.number().nonnegative()).optional(),
    main_character_post: z
      .object({
        id: z.string().min(1),
        photo: z.string().min(1),
        posted_at: dateString,
        likes: z.number().int().nonnegative(),
        comments: z.number().int().nonnegative(),
        avg_likes: z.number().int().nonnegative(),
      })
      .strict()
      .optional(),
    most_replied_story: z
      .object({
        id: z.string().min(1),
        photo: z.string().min(1),
        posted_at: dateString,
        replies_24h: z.number().int().nonnegative(),
      })
      .strict()
      .optional(),
    circle: z
      .array(
        z
          .object({
            handle: z.string().min(1),
            avatar: z.string().min(1),
          })
          .strict(),
      )
      .optional(),
    late_night: z
      .object({
        latest_local_time: z.string().regex(/^\d{2}:\d{2}$/),
        weekday: z.string().min(1),
        month: z.number().int().min(1).max(12),
      })
      .strict()
      .optional(),
    archetypes: z
      .object({
        primary: z
          .object({
            key: z.string().min(1),
            score: z.number().min(0).max(100),
          })
          .strict(),
        secondary: z
          .object({
            key: z.string().min(1),
            score: z.number().min(0).max(100),
          })
          .strict(),
        clues: z.array(z.string().min(1)),
      })
      .strict()
      .optional(),
    share_cards: z
      .object({
        identity_stat: z.tuple([z.string(), z.string()]),
        numbers_photo: z.string().min(1),
        top_interest: z.string().min(1),
      })
      .strict()
      .optional(),
    home_feed_post: z
      .object({
        author: z.string().min(1),
        location: z.string().min(1),
        photo: z.string().min(1),
      })
      .strict()
      .optional(),
  })
  .strict();

export type Persona = z.infer<typeof personaSchema>;

const metricKeys = [
  "totals",
  "monthly",
  "opening_photos",
  "feed_color",
  "explore_topics",
  "reels_categories",
  "fastest_rising",
  "ceramics_monthly",
  "main_character_post",
  "most_replied_story",
  "circle",
  "late_night",
  "archetypes",
  "share_cards",
  "home_feed_post",
] as const;

/** Maya and her teen variant carry the full demo record. Everyone else stays identity-only until numbers exist. */
export function assertPersonaRules(persona: Persona) {
  if (persona.persona_key === "maya" || persona.persona_key === "teen") {
    for (const key of metricKeys) {
      if (persona[key] === undefined) {
        throw new Error(`${persona.persona_key} is missing ${key}`);
      }
    }
  }
  if (persona.persona_key === "teen" && persona.profile.is_teen !== true) {
    throw new Error("teen must be a teen account");
  }
  if (persona.persona_key !== "teen" && persona.profile.is_teen) {
    throw new Error(`${persona.persona_key} is not the teen variant`);
  }
  if (
    (persona.persona_key === "emerging" || persona.persona_key === "established") &&
    persona.profile.account_type !== "creator"
  ) {
    throw new Error(`${persona.persona_key} must be a creator account`);
  }
  if (persona.totals && persona.monthly) {
    const posts = persona.monthly.reduce((sum, month) => sum + month.posts, 0);
    const stories = persona.monthly.reduce((sum, month) => sum + month.stories, 0);
    if (posts !== persona.totals.posts || stories !== persona.totals.stories) {
      throw new Error(`${persona.persona_key} monthly totals do not match totals`);
    }
  }
}

export function parsePersona(input: unknown): Persona {
  const persona = personaSchema.parse(input);
  assertPersonaRules(persona);
  return persona;
}
