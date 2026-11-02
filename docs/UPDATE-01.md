# UPDATE-01: Review of the step 13 build and the next work order

> Put this file at `docs/UPDATE-01.md`. Read it fully before writing code.
> Priority order for sources is now: `docs/DECISIONS.md` → this file → the six specs → design PNGs/HTML.
> First action: append section 2 (D12 to D19) to `docs/DECISIONS.md` and commit as `docs: add D12-D19`.

This update is based on three things:
1. `HANDOFF.md` from the step 13 build (commit `332bb1d`, repo `IGWRAPDEMO`).
2. A review of the repo itself (engine tests run, Swift sources read).
3. An 82-second screen recording of the app on the iPhone 17e simulator (iOS 27.2), reviewed frame by frame.

---

## 1. Where the build stands

### Confirmed good
- Steps 0 to 13 are committed in order and the handoff is accurate about what is and isn't built.
- Engine tests: **9 of 9 pass** with `deno test --allow-read supabase/functions/_shared/engine/`. Without `--allow-read` 5 fail with `NotCapable`. Nothing in the repo documents the flag (fixed in F0).
- Player pacing is right: 6 s per card, 9 s on 2, 10 and 12, card 11 waits for Reveal, reveal haptic fires, Identity/Numbers crossfade works.
- Every number on screen in the recording matches maya: 1,214 · 38 · 412 · 1,206 · 2,184 · 418 · 47 · 1,840 · 96% · 3:42 AM · 31/22/18/12/9.
- Teen omission of cards 8 and 9, chapter swipe, hold, swipe-down and tap zones are tested.

### Problems found
| # | Problem | Source | Severity |
| --- | --- | --- | --- |
| P1 | Persona sign-in calls Supabase at `127.0.0.1`. On a physical iPhone that address is the phone, so login fails before any card. This blocks Step 16, which can only be proven on a device | Repo review | **Blocker** |
| P2 | Cards print hardcoded `Maya*` constants (`MayaCards.swift`, plus strings in card files). The engine is not the source of truth in the app | Handoff + repo | High |
| P3 | Display headlines render taller than the designs. Card 1 line gaps too large; card 2 "A YEAR." and card 3 "HAD A COLOR." collide with their grids. Root cause: SwiftUI can't set line height below 1.0; the designs use 0.82 to 0.88 | Recording 5 s, 9 s, 31 s | High |
| P4 | On cards 12 and 13 the player chrome (progress bars + top row) sits inside the status bar, overlapping the clock | Recording 69 to 81 s | High |
| P5 | Toasts survive a card change: "Got it. We'll tune Explore." from card 4 still shows on card 5, covering "And you sent 1,206 of them to friends." | Recording 42 to 43 s | Medium |
| P6 | Card 13: "Go to your Hub" is clipped by the home indicator | Recording 72 to 81 s | Medium |
| P7 | Your Circle uses tile photos (brunch skillet, skyline) as people's avatars | Recording 54 to 59 s | Medium |
| P8 | Montage plays 15 s of plain gradient screens when month photos are missing. That's 18% of the recording with nothing on screen | Recording 12 to 26 s | Medium |
| P9 | Home shell: every story-tray avatar is an empty black circle; top bar has no wordmark | Recording 1 to 3 s | Medium (assets) |
| P10 | Unbuilt actions show "Not part of this demo" on screen (card 3 Share, card 13 Share) | Recording 33 s, 78 s | Low now, blocker for the pitch take |
| P11 | Card info sheet is empty; swipe-up opens it | Handoff | Step 14 |
| P12 | No share rendering, no Sharing to Stories, no Save/Send | Handoff | Steps 15 to 16 |

---

## 2. New decisions (append to `docs/DECISIONS.md`)

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

**D19. Order of work** is section 3 of this file. It replaces "Fixes worth doing" in `HANDOFF.md`. The P1 fix (offline bundles, Step 13.5) moves ahead of Step 14 because it blocks the physical-device test.

---

## 3. Work order

Same rules as before: one item at a time, restate Build + Done when, list files, build, verify, commit, report, wait for "next". Each UI item needs a `--reference` screenshot against the matching PNG in the report.

### Batch A: fix pass from the recording (do first, small commits)

#### F0. Test and tooling commands
- **Build:** root `deno.json` with tasks:
  - `test`: `deno test --allow-read supabase`
  - `export`: `deno run --allow-read --allow-write scripts/export-runs.ts` (script arrives in 13.5; add the task now pointing at it)
  - `check`: runs `test`, then `export`, then `git diff --exit-code ios/IGWrapped/Resources/Runs`
- Add a "Commands" section to `README.md`: deno tasks, `xcodegen generate`, `xcodebuild test` with the iPhone 17e destination, and the launch arguments from `HANDOFF.md`.
- **Done when:** `deno task test` passes 9/9 from a clean clone.

#### F1. Display headline line height (P3)
- **Build:** `DisplayHeadline` in `DesignSystem` that takes `lines: [String]` (from D17 copy), `size`, `lineHeight`, `weight`, `width`, `tracking`, `color`. Each line is its own `Text`, `.lineLimit(1)`, `.fixedSize()`, inside `.frame(height: size * lineHeight, alignment: .bottom)`; lines stacked in a `VStack(alignment: .leading, spacing: 0)`. Headline block height = `lines.count * size * lineHeight`, which is what the HTML layout assumes.
- Line heights per the HTML: display 0.86, hero 0.82, card 2/5/6/7 0.86, plot twist 0.82, identity name 0.80.
- Replace every multi-line headline: cards 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13a, 13b, home banner.
- Put the line breaks into the copy, matching the PNG wraps exactly. Examples: card 1 `2026 LOOKED\nGOOD ON\nYOU.` · card 2 `YOU HAD QUITE\nA YEAR.` · card 3 `YOUR FEED\nHAD A COLOR.` · card 7 `THE STORY THAT\nBROKE THE\nGROUP CHAT.` · card 12 `THE\nCURATOR`.
- **Done when:** with `--reference`, the baseline of each headline line is within 2 pt of the PNG on all listed cards, and no headline overlaps the element below it. Include before/after screenshots of cards 1, 2, 3.

#### F2. Chrome in the status bar on cards 12 and 13 (P4)
- **Build:** card backgrounds may `.ignoresSafeArea()`; the chrome layer never does. Chrome is laid out from the top safe-area inset on every card, the same way cards 1 to 11 do it today. Look for an `.ignoresSafeArea()` on a container that also wraps chrome in the reveal and share-card views.
- **Test:** UI test asserting the progress-bar container's `frame.minY` is equal on cards 1, 12 and 13.
- **Done when:** the test passes and screenshots of cards 12 and 13 show the clock clear of the bars.

#### F3. Toast lifecycle (P5)
- **Build:** toasts belong to the current card. Clear the toast on card advance, back, chapter swipe, hold start, dismiss and info-sheet open. Max lifetime 2.0 s.
- **Test:** `StoryPlayerModel` unit test: set toast on card 4, advance, toast is nil.
- **Done when:** test passes; tapping More of this then tapping forward shows no toast on card 5.

#### F4. Card 13 bottom stack (P6)
- **Build:** the toggle, Share pill and "Go to your Hub" sit above the bottom safe-area inset with 12 pt clearance. If the stack can't fit above the identity card's own 100 pt footer zone, shrink spacing, not type.
- **Done when:** on iPhone 17e and the smallest supported simulator, "Go to your Hub" is fully visible and tappable (44 pt target).

#### F5. Person avatars (P7, P9 tray)
- **Build:** one `PersonAvatar(handle:photo:)` used by the story tray, feed post header, Story viewer header, Circle card, tab-bar profile. If `photo` is missing: initials (first letter of handle, uppercase) on a solid color picked deterministically from the handle among `igPink, igOrange, igViolet, closeGreen, igYellow` (ink initials on yellow and green, white on the others). Remove the tile-photo fallback in the Circle card.
- **Done when:** no person anywhere shows a place/food photo; tray and Circle show initials until headshots are added.

#### F6. Montage without photos (P8)
- **Build:** if any of `m-01`…`m-11` is missing, the Play tile on card 2 shows a disabled state (same size, 40% opacity, label "Add month photos to play") and the montage doesn't start. With all 11 present, current behavior.
- **Done when:** with today's assets, tapping Play does nothing visible except the disabled state; no gradient montage plays.

#### F7. Wordmark frame (P9)
- **Build:** `IGTopBar` reserves the wordmark's exact frame measured from `01-home.png` and loads `Resources/Brand/instagram-wordmark` (PDF or PNG, template rendering white in dark mode) when present. Absent: empty frame, nothing drawn.
- **Done when:** dropping a wordmark file into `Resources/Brand/` shows it in the right place with no code change.

#### F8. Pitch mode (P10, D18)
- **Build:** `--pitch` launch argument per D18. Centralize unbuilt actions behind one `Feature.isBuilt(_:)` check so pitch mode and the toasts read from one list.
- **Done when:** a full run with `--pitch` shows zero "Not part of this demo" toasts and no debug UI.

**After F0 to F8:** record the same run again (banner → card 13, tap through at the same pace) and attach it with a list of any remaining mismatches.

---

### Batch B: Step 13.5, offline run bundles (P1, P2)

**Build**
1. `scripts/export-runs.ts` (Deno): runs the engine for `maya`, `maya` with `is_teen = true` (save as `maya-teen`), `ghost`, `emerging`, `established`. Writes `ios/IGWrapped/Resources/Runs/<persona>.json` in exactly the shape `build-run` persists: `run`, `metrics`, `archetypes`, `cards` (with `payload` and `copy`, D17 line breaks included). Pretty-printed, keys sorted, so diffs are readable.
2. Engine copy layer owns every sentence that contains a number or a line break (e.g. `"418 comments. Unhinged ones."`, `"August was your busiest month: 9 posts, 61 Stories."`, `"YOU HAD QUITE\nA YEAR."`).
3. Swift:
   - `RunBundle: Codable` mirroring the JSON.
   - `protocol RunRepository { func load(persona: String) async throws -> RunBundle }`
   - `BundledRunRepository` (default, D12) reads `Resources/Runs/<persona>.json`.
   - `SupabaseRunRepository` only when `--backend` and Config has a URL. Keep today's Supabase code path working behind it.
   - Persona login (S02) picks a bundle with no network call in default mode.
   - Every card view takes its payload and copy from the `RunBundle`. **Delete `MayaCards.swift`** and every other `Maya*` constant.
   - `FeedbackStore`: default mode appends to a local JSON file in Application Support; `--backend` mode inserts as today.
4. Tests:
   - Swift Testing: decode `Runs/maya.json`, assert the canonical numbers from `docs/05-BACKEND-SCHEMA.md` §5 and the D17 headline lines for cards 1, 2, 3.
   - Deno: export output equals `buildRun()` output for each persona (snapshot).
   - `deno task check` (F0) in the report.

**Done when**
- Simulator in airplane mode: banner → login → Building → card 1 → card 13 with no errors and no network calls (log it).
- Change `totals.saves` in `data/personas/maya.json` to 1,215, run `deno task export`, rebuild: cards 11, 12, 13a and 13b show 1,215. Then revert.
- `grep -rn "Maya" ios/IGWrapped --include=*.swift` returns only previews/tests.
- On a physical iPhone (free Apple ID signing is fine): banner → card 13 works with wifi off.

---

### Batch C: Step 14, card info sheet (P11)

**Build**
- Opens from (i) and swipe-up. Hidden on cards 1 and 11 (no metrics), as today.
- Content per card, from the card's `metricIds`:
  - Provenance badge: Measured (solid pill), Estimated (dotted border), Inferred (dashed border), plus one line: Measured "Counted directly from your activity." · Estimated "Calculated from a sample of your activity." · Inferred "Our best guess from what you engaged with."
  - Window: "Jan 1 to Nov 15, 2026".
  - Method: the metric's `method` string, verbatim. Reels must read exactly: "Top 5 categories by share of your Reels watch time. Other categories: 8%."
  - When a card has several metrics, list each with its own badge and method.
- **This looks wrong:** list of the D13 reasons → writes `card_feedback` (kind `looks_wrong`, reason key) → toast "Thanks. We'll check it." (F3 rules apply).
- **Hide this card:** confirm ("Hide this card from your Wrapped?" Hide / Cancel) → card removed from the player sequence and persisted (`hiddenCards` set saved per run). Unhide comes with Step 19; until then `--reset-session` clears it.
- Styling: share-sheet sheet styling (`#121214`, 26 pt top radius), per DECISIONS.
- Accessibility: VoiceOver reads badge, window and method as one element per metric.

**Done when** every card 2 to 13 opens a sheet with the right metrics; hiding card 9 removes it from the sequence and progress bars (12 segments) and survives relaunch; a looks-wrong reason writes a row (local file in default mode).

---

### Batch D: Step 15, share rendering

**Build**
- `ShareRenderer` using `ImageRenderer` on dedicated share views (not the live card views with chrome).
- Formats: Story 1080×1920, Post 1080×1350, Square 1080×1080. Only the **Bold** style until Step 20 (DECISIONS).
- Shareable outputs: 13a Identity card, 13b Numbers card, plus each shareable journey card (3, 4, 5, 6, 7, 9, 10, 12) in Story format.
- Story safe zones: no key content in the top 250 px or bottom 340 px.
- "Show on card" toggles: `@handle` (on), the card's stat lines (on), second personality (off), cover photo on Numbers card (on). Toggles change the render only.
- All numbers and copy come from the `RunBundle`; never read view state.
- Card 8 is never renderable (private). Assert it in a test.

**Tests:** exported PNG pixel dimensions per format; for maya, OCR-free check that the render uses the same `copy` strings as the card (compare the strings passed into the view); card 8 render throws.

**Done when** the three formats export for 13a and 13b, plus Story for the other shareable cards, and the attached exports match `13a-identity-card.png` and `13b-numbers-card.png` in layout.

---

### Batch E: Step 16, share sheet and Sharing to Stories

**Build (S10 per `03-APPFLOW.md`, scope per D15)**
- Share sheet UI per `design/screens/S10-share-sheet.png`: Identity / Numbers picker, format buttons, style row (Bold only enabled, others hidden in `--pitch`), "Show on card" chips, action row.
- **Your story:** follow Meta's Sharing to Stories docs exactly:
  - `LSApplicationQueriesSchemes` contains `instagram-stories`.
  - URL: `instagram-stories://share?source_application=<FACEBOOK_APP_ID>` (from `Config.xcconfig` → Info.plist).
  - `UIPasteboard.general.setItems([[ "com.instagram.sharedSticker.backgroundImage": pngData, "com.instagram.sharedSticker.backgroundTopColor": "#D300C5", "com.instagram.sharedSticker.backgroundBottomColor": "#D300C5" ]], options: [.expirationDate: Date().addingTimeInterval(300)])`, top/bottom colors = the card's background token.
  - `canOpenURL` false → toast "Instagram isn't installed" and offer Save.
  - Empty `FACEBOOK_APP_ID` → toast "Add a Facebook App ID in Config.xcconfig", do nothing else.
- **Save:** `PHPhotoLibrary` add-only (`NSPhotoLibraryAddUsageDescription`: "Save your Wrapped cards to Photos."). Denied → toast with a Settings deep link.
- **Send:** `UIActivityViewController` with the PNG only.
- **Copy link:** disabled per D15.
- Analytics: append `share_events` locally (destination story/save/send).

**Done when**
- Simulator: the full flow runs, and Your story shows the "Instagram isn't installed" path.
- **Physical iPhone: I confirm a Wrapped Identity card opens in the real Instagram Story composer.** You can't mark this done yourself. Give me step-by-step device run instructions for a free Apple ID (signing team, trust profile, Config), then stop and wait.

---

### Batch F (after I confirm Step 16)

- **Step 17 web landing:** hosted Supabase project (free tier) + Vercel. Share uploads the PNG to Storage and inserts `share_snapshots` only when online; `/s/[slug]` shows the image, a See yours button and "What's Instagram Wrapped?". Re-enable Copy link (undo D15). The link sticker is added by hand in Instagram; Copy link copies it first with the toast "Link copied. Add it with the link sticker."
- **Step 18 Hub:** per `design/screens/S08-wrapped-hub.png`; wire card 13's "Go to your Hub" and the player's close/swipe-down to it.
- **Partial Step 21:** walk all 13 cards with VoiceOver and with Reduce Motion on; report each card's behavior in a table.

Deferred, in this cut order: Step 19 privacy (beyond hide), Step 20 Remix, Step 22 Creator, Step 23 Together/Guess.

---

## 4. Assets I owe (don't draw any of these)

| File | Where it goes | Spec | Unblocks |
| --- | --- | --- | --- |
| `instagram-wordmark.pdf` (or PNG), `instagram-glyph.pdf` | `ios/IGWrapped/Resources/Brand/` | Vector preferred | F7, home shell |
| `maya-profile.jpg` | `design/photos/` → bundle | Square headshot, ≥400 px | Tray, tab bar, Story header |
| `friend-dee.jpg`, `friend-jules.jpg`, `friend-nico.jpg`, `friend-sam.jpg`, `friend-tori.jpg` | same | Square headshots | Tray, Circle |
| `m-01.jpg` … `m-11.jpg` | same | Square, one per month | Card 2 tiles, montage |
| `story-0314.jpg` | same | 9:16 | Card 7 |
| Chapter audio ×5 | `ios/IGWrapped/Resources/Audio/` | Memories, Interests, Moments, People, Identity | Music |
| Facebook App ID | `ios/Config.xcconfig` | From developers.facebook.com | Step 16 |

When files land, re-run `deno task export` if any payload references change, rebuild, and post a screenshot of each affected screen.

---

## 5. Pitch take checklist (for when Step 16 is confirmed)

One continuous take on the physical iPhone, `--pitch`, Do Not Disturb on, full battery, wifi on (Instagram needs it).
1. Home feed (2 s) → tap the banner.
2. Building → Before we start → Start.
3. Cards 1 to 10 at the player's own pace; tap ahead on 3 and 5 only. Play the montage only if all 11 month photos exist.
4. Card 11 → Reveal → card 12 (hold 3 s on the name).
5. Card 13 → Share → Your story → Instagram composer opens with the card → post.
6. Open your own Story to show it live.
7. (After Step 17) cut to a second phone: tap See yours → landing page.

Target length 75 to 90 s. No toasts, no debug overlays, no "Not part of this demo" anywhere in the take.

---

## 6. Do not touch (from `HANDOFF.md`, still true)

- `IGStoryViewer` text layout (center `ZStack` then offset).
- `CubeFace` rotation only while the angle ≥ 0.5°.
- No `.accessibilityIdentifier` on a parent that wraps controls.
- No `.frame(maxWidth: .infinity, maxHeight: .infinity)` on a button.
- Chrome stays intrinsic height.
- Config URL format `http:/$()/127.0.0.1:54321`.

---

## 7. Report format for every item

```text
Item: F1 Display headline line height
Build: <3 to 5 lines>
Files: <list>
Verified: <tests run + result, screenshot paths, --reference notes with any offsets in pt>
Remaining mismatches: <list or "none">
Questions: <list or "none">
Commit: <hash> <message>
```

Kickoff line to paste into Cursor:

> Read `docs/UPDATE-01.md` fully. Append its section 2 to `docs/DECISIONS.md` and commit. Then start Batch A with F0, one item at a time, using the report format in section 7. Wait for my "next" after each item.
