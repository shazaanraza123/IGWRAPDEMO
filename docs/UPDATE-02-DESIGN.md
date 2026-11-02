# UPDATE-02: Instagram 2026 design language

This one is design only: the new wordmark, typography, gradient and color, and layout. Engine, backend and sharing work stay in `UPDATE-01.md`. Use the report format from `UPDATE-01.md` §7 for every item.

---

## 1. What changed at Instagram (Aug 13, 2026)

Instagram refreshed its identity for the first time since 2016. This is the confirmed part:

| Area | What changed | Confidence |
| --- | --- | --- |
| Wordmark | Still a script, but bolder and simpler. Serifs are flattened and detached from the next letter, so the letters read more independently. The opening "I" and a few strokes stay handwritten. | Confirmed (Meta, Dezeen, Design Compass) |
| App icon / camera glyph | Unchanged. | Confirmed (Transform) |
| Gradient | "Remains a core part of our brand" but is used **more subtly**. | Confirmed (Meta) |
| Type | Instagram Sans updated. New: **Instagram Pen** (handwriting) and **Instagram Mono** (monospace). | Confirmed (Meta) |
| Motion, layout, UI | Refreshed, with "more room to breathe" so "the community's work is what carries the energy." | Confirmed as a direction; no specs published |
| Rollout | The wordmark is live in the app now. The full identity rolls out "through 2026 and beyond." | Confirmed (Meta) |

The people behind it are Jasmine Probst (Director of Product Design, Instagram) and May Hartono (Director of Brand Design, Meta). They are on the pitch list, so the demo has to look like it belongs in the 2026 app and not the 2016 one.

**Not published:** weights, color values, motion curves, spacing specs. **Don't invent them.** Wherever this doc needs a number, it comes from a real screenshot of the current app or from the boards I update.

---

## 2. Decisions (append to `docs/DECISIONS.md`)

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

---

## 3. Work items

### G1. 2026 wordmark in the top bar
- **Build:**
  - In `IGTopBar.swift`, change the image lookup from `"Wordmark"` / `"ig-wordmark"` to `instagram-wordmark`.
  - Remove `IGSpace.wordmarkWidth = 132` and `wordmarkHeight = 28` from `Tokens.swift`. Those values were sized for the old mark, and the new one is bolder and spaced differently.
  - Size the mark by height with `.aspectRatio(contentMode: .fit)`. Take the height and the left/top offsets from `design/reference/instagram/01-home-2026.png`, **not** from `design/screens/01-home.png`, which was drawn around the old mark.
- **Done when:**
  - Dropping the file in shows it correctly with no code change, within ±1 pt in a `--reference` overlay.
  - `grep -rn "wordmarkWidth\|ig-wordmark" ios/` returns nothing.
  - The report has a side-by-side of our top bar next to the real one.

### G2. Every other wordmark placement
- **Build:**
  - Find every spot that shows the wordmark: Story header, share card footers (13a/13b), the in-Story sticker, and the web landing at `/s/[slug]`.
  - Every placement uses the same asset. On web, export it as SVG to `web/public/brand/` (gitignored like the iOS copy).
- **Done when:** the report lists every placement with a screenshot of each.

### G3. Reference screenshots refreshed (D20)
- **Build:**
  - Add `Captured: YYYY-MM-DD` and `App version` columns to `design/reference/instagram/README.md`.
  - Flag any shot older than Aug 13, 2026. I'll retake the flagged ones.
  - Re-run the shell overlay pass (HANDOFF item 5) against the new shots for: top bar, tab bar, Story tray, Story viewer header, and composer.
- **Done when:** every row has a date after Aug 13, 2026, and the report lists each overlay offset in pt (or "none").

### G4. Typography (D22)
- **Build:**
  - The chrome stays on SF Pro (system). There's no change here, because real Instagram UI text is system type.
  - Cards: if `design/fonts/InstagramSans*` exists, register it and make it the card display/body face behind one token in `Typography.swift`, so the switch is a one-line change. Otherwise keep Archivo.
  - Method and provenance lines in the info sheet (Step 14) and the "how we counted" text use a single `monoCaption` token. That token resolves to Instagram Mono if licensed, else **SF Mono** (an Apple system font, so it's an honest fallback, not a lookalike).
  - Instagram Pen: no use unless it's licensed. Don't add handwriting anywhere as a stand-in.
- **Done when:** the Styleguide screen shows which face each token resolved to, and swapping the font file changes it with no other code edits.

### G5. Gradient and color audit (D21): audit first, no restyling yet
- **Build:** produce a table with one row per card (1 to 13, plus 13a/13b): current field color, where brand color or gradient appears, and a screenshot. Start from these full-bleed brand fills already in the code:
  - `YearMemoriesCard.swift:118`: `igPink` field
  - `IdentityCards.swift:537`: `igMagenta` field
  - `IdentityCards.swift:558`: `igPink` field
  - `OpeningCard.swift:33`, `WrappedComponents.swift:185` and `:326`, and `IdentityCards.swift:639`: gradients
  - `MomentsCards.swift:436`: `storyRing` used as a fill
- **Do not restyle anything in this item.** I'll update the design boards to D21 from your table, then G6 implements them. Don't freelance the new look.
- **Done when:** the table and screenshots are in the report.

### G6. Implement the restrained card set (after the boards are updated)
- **Build:**
  - Match the updated boards card by card.
  - `storyRing` stays exactly as it is on rings and the progress bar, because that's live Instagram UI, not decoration.
  - No new color tokens unless they're on a board. Remove tokens that are no longer used.
- **Done when:**
  - Every card matches its board in a `--reference` overlay.
  - Full-bleed brand color appears only on cards 1, 12 and 13.
  - The report has before/after screenshots of all 13.

---

## 4. Order

1. Finish UPDATE-01 Batch A first, so small fixes don't collide with restyling.
2. G1, G3, G4 (any order). G2 after Step 15 exists.
3. G5, then I update the boards, then G6.
4. **All of G1 to G6 must be done before the pitch take** (`UPDATE-01.md` §5).

## 5. Assets I owe

| File | Where it goes | Unblocks |
| --- | --- | --- |
| 2026 wordmark, vector (the Aug 13, 2026 version) | `ios/IGWrapped/Resources/Brand/instagram-wordmark.pdf` | G1, G2 |
| `01-home-2026.png` plus retakes of any flagged shot | `design/reference/instagram/` (same phone as the other shots) | G1, G3 |
| Instagram Sans / Mono / Pen, only if I can license them | `design/fonts/` | G4 |
| Updated boards for D21 | design canvas → `design/screens/` | G6 |

## 6. Do not

- Draw, trace, recolor or gradient-fill the wordmark or glyph.
- Use lookalike fonts for Instagram Sans, Pen or Mono.
- Guess at Instagram's new spacing or motion values. Use screenshots or the boards.
- Touch anything in `UPDATE-01.md` §6.

## Sources

- [The new Instagram brand identity, Design at Meta](https://www.meta.com/design-at-meta/blog/the-new-instagram-brand-identity/)
- [Instagram rebrand wordmark script, Dezeen](https://dezeen.com/2026/08/14/instagram-rebrand-wordmark-script-2026/)
- [Instagram wordmark refresh 2026, Design Compass](https://designcompass.org/en/2026/08/14/instagram-wordmark-refresh-2026/)
- [Instagram refresh, first in a decade, Transform](https://www.transformmagazine.net/articles/2026/instagram-refresh-first-in-a-decade/)

Kickoff line to paste into Cursor:

> Read `docs/UPDATE-02-DESIGN.md` fully. Append its section 2 (D20–D23) to `docs/DECISIONS.md` and commit. Once UPDATE-01 Batch A is done, start G1, one item at a time, using the report format in UPDATE-01 §7. Wait for my "next" after each item. G5 is an audit only: don't restyle cards until I send updated boards.
