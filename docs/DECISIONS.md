# Decisions

> This file wins. If it disagrees with `docs/UPDATE-02-DESIGN.md`, `docs/UPDATE-01.md`, `docs/01-PRD.md` through `docs/06-IMPLEMENTATION-PLAN.md`, `data/personas/maya.json`, `design/source/*.dc.html`, or a PNG, follow this file.
> `docs/UPDATE-01.md` section 3 is the work order until Batch A is done. Then `docs/UPDATE-02-DESIGN.md` section 3.
> Recorded 2026-10-17 from the review of the kit. D12–D19 were appended from `docs/UPDATE-01.md` on 2026-11-02. D20–D23 were appended from `docs/UPDATE-02-DESIGN.md` on 2026-11-02. Where a later decision disagrees with an earlier section, the later decision wins.

## 1. Chapters

Five chapters drive behavior (music and the cube swipe):

| Chapter | Cards |
| --- | --- |
| Memories | 1–2 |
| Interests | 3–5 |
| Moments | 6–7 |
| People | 8–9 |
| Identity | 10–13 |

`Chapter` has five cases: `memories`, `interests`, `moments`, `people`, `identity`.

"Memories → interests → people → identity" in the PRD is the narrative arc, not the enum.

Eyebrow text is copy only. It is not a chapter id. Keep every eyebrow exactly as the HTML has it. Card 9 stays "YOUR HABITS".

## 2. Photo ids

`maya.json` ids are canonical:

`tile-1` … `tile-5`, `m-01` … `m-11`, `main-character`, `year-card`, `story-0314`, `feed-chicago`, `maya-profile`, `friend-<name>`.

On-disk renames: `tile-brunch` → `tile-1`, `tile-city` → `tile-2`, `tile-concert` → `tile-3`, `tile-hike` → `tile-4`, `tile-rooftop` → `tile-5`.

Schema payloads use these ids. A missing photo renders as the gradient placeholder tile from the designs (the same treatment as card 2's PNG). A missing image never fails the screen.

## 3. Card 13 in the player

Render the Identity card (13a) full-bleed as the card itself. Its own content already keeps the bottom 100 pt clear. In that zone, stack:

1. `SegmentedToggle` "Identity card / Numbers card" (the same component as the Hub's Personal/Creator toggle)
2. The black "Share" pill
3. A "Go to your Hub" text link

Toggling swaps to 13b with a crossfade. Player chrome (progress bars and the top row) stays on top, as on the other cards.

## 4. Chrome

The HTML wins for pixels, with these normalizations:

- The top row on every card is (i), mute, X. Replace the Pause button on cards 1, 2, and 11 with (i). Hide (i) on cards 1 and 11 (they have no metrics), leaving mute and X. Pause is hold-to-pause only, the way Instagram does it.
- Bottom pill copy varies on purpose. "Share" when the pill sits next to a provenance line (cards 3, 6, 10). "Share this story" when the pill is standalone (cards 4, 5, 7, 9). Card 8 is the private lock pill and has no share. Cards 1 and 2 have no pill. They are shareable from the Hub tile and from the later (i) / share flow.
- The HTML files may still draw a Pause button on cards 1, 2, and 11. This normalization wins over those files.

## 5. Circle order

The engine outputs the five handles sorted alphabetically: `dee.films`, `jules.mp`, `nico_k`, `sam.wav`, `tori.eats`. The PNG's order is illustrative. Positions and styling come from the PNG. Names come from the engine.

## 6. Banner copy

"About 3 min" is "About 2 min".

## 7. Card 6 copy, and every numeric sentence

The card 6 line is a template in the engine's copy layer: `"{comments} comments. Unhinged ones."` with `comments` = 418 from `maya.json`.

Any sentence that contains a number lives in a `copy` object on that card's payload. Views display those strings verbatim. Views never assemble numbers into sentences.

A big number drawn as its own figure, with a separate caption that does not contain the number, stays a structured field. That is not sentence assembly. Examples: the `47` on card 7 with the caption "replies in a day"; the `2,184` like bubble; the three reason columns on card 12 (`value` + `label`).

Finished `copy` strings for maya are in `docs/05-BACKEND-SCHEMA.md` section 5. The Hub window line and the "N cards. …" summary are engine copy on the run, because the count changes for the teen and lite tiers.

## 8. Reels 92%

Intended. These are the top 5 shares of total Reels time. The other 8% is spread across smaller categories and is not a row on the card.

Info-sheet method line: "Top 5 categories by share of your Reels watch time. Other categories: 8%."

## 9. Undrawn screens

Build undrawn screens from the design system, using the nearest designed pattern. No new visual ideas.

| Screens | Pattern |
| --- | --- |
| S02 login, S03 building, S04 before we start, S05 edition picker | Ink background, card typography, Hub buttons and segmented controls |
| S09 info sheet, S12 privacy, S11 remix | Share-sheet styling (`#121214` sheet, `ToggleChip`, `ToolRow`) |
| S13, S14, S16 | Hub row patterns |
| Web landing (S17) | The shared PNG centered on ink, one white "See yours" pill, one text link |

Designs for S02 and S09 may arrive before Step 6. If they do, they override this section.

Only the Bold remix skin (the current designs) is required until Step 20.

"Push / profile menu" is out of scope. Entry is the home banner and the Wrapped tray bubble only. `design/app-flow-map.png` still draws that box; ignore it.

`design/screens/S17-identity-card-in-story.png` is renamed `design/screens/story-posted-preview.png`. S17 means the web landing.

## 10. Instagram references

`design/reference/instagram/` has no screenshots yet. Steps 0–6 do not need them. They are added before Step 7. If they are still missing when Step 7 starts, stop and ask. Never draw the wordmark or glyph, and never invent Story motion.

## 11. Small mismatches

- The algorithm PNG shows the selected state as an example. The default state is all unselected. "More of this" becomes selected only after a tap.
- Controls drawn at 36 pt keep that visual size. The hit area expands to 44 pt with `contentShape` / padding.
- Navigation follows `docs/03-APPFLOW.md`. The `href` wiring inside `design/source/*.dc.html` is not navigation.

## 12. Step 0 environment

- Copy the kit into this repo. XcodeGen project. Local `supabase start` via Docker. Blank launch.
- Install XcodeGen, the Supabase CLI, Deno, and Node if they are missing. Hosted Supabase and the Facebook App ID wait for the steps that use them.
- There is no iPhone 16 simulator. Use the newest installed 6.1" non-Pro iPhone simulator and name it in the step report. Do not download simulator runtimes without asking.
- If Docker is not installed, stop and say so. Do not install Docker or OrbStack.

## 13. Update 01

**D12. Offline is the default data source.** The app ships engine output as bundled JSON and needs no network for the demo. Supabase is used only when `SUPABASE_URL` is set in `Config.xcconfig` **and** the app is launched with `--backend`. Instagram itself still needs network for Step 16; our app does not.

**D13. "This looks wrong" reasons**, in this order, stored as `card_feedback.reason` keys. No free text.

| Key | Label |
| --- | --- |
| `number_off` | The number seems off |
| `not_me` | That's not me |
| `dont_remember` | I don't remember this |
| `other` | Something else |

**D14. `days_active` (301)** stays a metric. No card shows it. Don't add it anywhere.

**D15. Step 16 scope.** Ship "Your story", "Save" and "Send" (image only). "Copy link" and the See yours link are disabled until Step 17, with the toast "Links come with the web page".

**D16. Missing-asset fallbacks never produce dead air or wrong subjects.**

- Missing person photo (Maya or a friend): initials on a solid token color inside the normal ring.
- Missing month photo: the gradient tile from the design (already done) on card 2; the montage doesn't play (F6).
- Missing Story photo: the gradient tile (already done).
- Missing wordmark: reserve its exact frame from `01-home.png`, draw nothing. Never draw or approximate the wordmark or glyph.
- Never substitute a tile/place photo for a person.

**D17. Headline line breaks are content.** Every display/hero headline in the card payload `copy` carries explicit `\n` breaks that match the HTML in `design/source/`. Views never decide where a headline wraps.

**D18. Pitch mode.** Launch argument `--pitch` hides every action that isn't built (no "Not part of this demo" toasts; the control is omitted or inert with no visual change), hides `ReferenceOverlay` and debug UI, and turns off progress save/resume so every take starts at card 1. Default (no flag) keeps today's behavior for development.

**D19. Order of work** is section 3 of `docs/UPDATE-01.md`. It replaces "Fixes worth doing" in `HANDOFF.md`. The P1 fix (offline bundles, Step 13.5) moves ahead of Step 14 because it blocks the physical-device test.

## 14. Update 02

**D20. Instagram chrome matches the current app.**
- Top bar, tab bar, Story viewer and composer match the Instagram build installed today, verified against screenshots dated after Aug 13, 2026.
- Any reference shot older than that doesn't count.

**D21. Restraint for the cards, with loud moments.**
- Photos and the user's own content carry the energy. Full-bleed brand color is reserved for three moments: **card 1 (opening), card 12 (personality reveal) and the card 13 share cards**.
- Every other card uses `ink` or `paper` (or the user's photos) as the field, with brand color only as an accent: a word, a sticker, a ring, a progress segment.
- Why: the team we're pitching just chose restraint. A Wrapped that's pink and magenta wall to wall reads as a 2016 Instagram knockoff. The tradeoff is that Wrapped is supposed to feel like a celebration, which is why the three peak moments keep full color.

**D22. Brand fonts only from licensed files.**
- Instagram Sans, Pen and Mono are used only if a licensed copy is in `design/fonts/`.
- Never pull them from font-mirror sites, and never fake them with a lookalike, especially a handwriting font standing in for Pen. A fake brand font is the fastest way for a brand designer to stop taking the demo seriously.

**D23. The wordmark is an asset, never drawn.**
- One file, `Resources/Brand/instagram-wordmark.pdf`, with template rendering: black on light, white on dark.
- No gradient fill, no tracing, no SwiftUI paths. If the file is missing, the frame stays empty.
