# Handoff for Claude

Instagram Wrapped concept prototype. Native SwiftUI iPhone app, synthetic persona data only, not affiliated with Instagram. Built one implementation-plan step at a time through step 13. Steps 14 through 24 are not done. This file is the status report. `docs/DECISIONS.md` still wins over this file if they disagree.

Repo this was pushed from: local `main` at commit `7c288b0` plus this handoff. The previous GitHub remote was `https://github.com/shazaanraza123/IGWRAPPEDMOCK.git` and was 14 commits behind this work. This copy is `https://github.com/shazaanraza123/IGWRAPDEMO`.

## How to run it

1. Open `ios/IGWrapped.xcodeproj` in Xcode. Do not open the repo root. The project is generated from `ios/project.yml` with XcodeGen. If you change sources, edit `project.yml` and run `xcodegen generate` from `ios/`. Do not hand-edit the pbxproj.
2. Scheme `IGWrapped`. Destination: newest installed 6.1 inch non-Pro simulator. On the build machine that was **iPhone 17e, iOS 27.2** (390×844 pt). This Xcode has no `Simulator.app`. The phone window is **Device Hub** (`/Applications/Xcode.app/Contents/Applications/DeviceHub.app`).
3. Copy `ios/Config.example.xcconfig` to `ios/Config.xcconfig` if it is missing. It is gitignored. Local Supabase URL is written as `http:/$()/127.0.0.1:54321` because `//` starts an xcconfig comment. `FACEBOOK_APP_ID` is empty.
4. Persona sign-in needs local Supabase (`supabase start`, Docker). Without it, the sample login shows an error. The story player itself can be opened with no backend.
5. Useful launch arguments, set in the scheme or via `simctl launch`:
   - `--player` opens the story player on card 1 and does not resume saved progress
   - `--player-card N` and `--player-paused`
   - `--teen` omits cards 8 and 9
   - `--reference` draws the design PNG at 50 percent on top of the current card (cards 1–13)
   - `--numbers` opens card 13 on the Numbers face
   - `--reset-session` signs out and clears the “intro seen” flag
   - `--friend-story` opens Jules’s fake story

Tests: `xcodebuild test` on scheme `IGWrapped`, destination `platform=iOS Simulator,name=iPhone 17e,OS=27.2`. Unit tests are Swift Testing. Gestures are XCUITest. `simctl` and `xcodebuild` against the simulator need to run outside the sandbox or CoreSimulator fails.

## Direct answers to the pitch checks

### 1. Step 7, Instagram shell fidelity

The reference shots are in the repo. They were not invented from memory. `design/reference/instagram/` contains:

- `01-home.png`
- `02-home-post-full.png`
- `03-story-tray-closeup.png`
- `04-tab-bar-dms.png`, `04-tab-bar-profile.png`, `04-tab-bar-reels.png`, `04-tab-bar-search.png`
- `05-story-viewer.png`
- `06-story-viewer-paused.png`
- `08-post-detail.png`
- `09-share-sheet.png`
- `video-story-open-close.mp4`
- `README.md`

What was actually checked:

- The home shell overlay uses **only** `01-home.png`. Colors and chrome positions in `Tokens.swift` are commented as measured from that file.
- The friend-story viewer was checked against `05-story-viewer.png` and `video-story-open-close.mp4`.
- The other shots are **not** wired as overlays. Tab screens are placeholders with the real tab bar. Card 6’s post cover is a simple full-screen photo, not the Instagram post-detail chrome in `08-post-detail.png`. The share sheet in `09-share-sheet.png` is not built (that is step 16).
- The Instagram wordmark and glyph are not drawn. They are supposed to come from `ios/IGWrapped/Resources/Brand/`, which is gitignored and was never supplied. The top bar is empty where the wordmark should be. An Instagram designer will notice that, and will also notice any shell drift that was not overlay-checked against shots 02, 03, and 04.

### 2. Step 16, the share loop

Not built. A Wrapped card does **not** open the real Instagram Story composer. There is no `instagram-stories://` handoff, no pasteboard payload, no Save / Send / Copy link, and no `share_snapshots` upload. `FACEBOOK_APP_ID` is blank. This was never run on a physical iPhone. Every Share pill toasts “Not part of this demo”. The web route `web/app/s/[slug]/page.js` returns “Snapshot {slug} is not wired yet.”

This is the key missing moment for the pitch video. A simulator cannot prove it even after it is built.

### 3. The numbers

Two different things are true, and they must not be collapsed into one.

The engine is the source of truth **in Deno**. `supabase/functions/_shared/engine` computes metrics and card copy. Tests assert Maya’s canonical set from `docs/05-BACKEND-SCHEMA.md` section 5, including `days_active === 301`. Persona data is `data/personas/maya.json`.

The Swift cards do **not** read that engine output. Each screen prints a hardcoded `Maya*` string copied from the schema. If the engine changed, the UI would not change. Views do not assemble numeric sentences. The strings were copied whole.

Numbers that are on screen and match Maya:

| Value | Where |
| --- | --- |
| 1,214 saves | Teaser clue, personality reasons, identity card, numbers card |
| 38 posts | Teaser, personality reasons, numbers card |
| 2,184 likes | Main-character post |
| 418 comments | “418 comments. Unhinged ones.” |
| 47 replies | Group-chat card, caption “replies in a day” |
| 412 Stories, 1,206 Reels sent | Numbers card |
| 1,840 liked posts | Feed-color footnote |
| 96% | Teaser and personality reasons |
| 3:42 AM | 3AM card |

`301` days active is in `maya.json` and the engine test. **No card draws it.** That is not a wrong number on screen. It is an unused canonical metric.

Known UI gaps that are not wrong numbers: missing month photos `m-01`…`m-11` use gradients; missing `story-0314.jpg` uses a gradient; Reels category taps show three gradient tiles, not real Reel frames. The category percents (31, 22, 18, 12, 9) are the schema values.

### 4. Steps that were skipped, and the ones that were only partly done

| Step | Status |
| --- | --- |
| 0–6 Scaffold, tokens, personas, schema, seed, metrics engine, card engine, persona sign-in | Done and committed. Sign-in was proven against local Supabase, including a feedback row insert. |
| 7 Home shell | Done, with the fidelity limits above. |
| 8 Friend story viewer | Done. Open, close, and swipe-down were UI-tested. |
| 9 Story player | Done. Tap zones, hold, swipe down, chapter cube, autoplay, info-sheet **shell**, mute. |
| 10 Cards 1–4 | Done. Opening, year plus a 15s montage, feed color, algorithm. Algorithm “More of this” writes `card_feedback` and toasts only after the insert succeeds. |
| 11 Cards 5–9 | Done. Teen skip of cards 8 and 9 is in the model and unit-tested. `--teen` is the demo hook. A real teen persona through the entry flow was not UI-tested end to end. |
| 12 Cards 10–13 | Done. Reveal turns autoplay off and uses `.sensoryFeedback(.success)`. Identity/Numbers toggle crossfades. Hub link toasts because the Hub is step 18. |
| 13 Entry | Done. Banner and tray open Building (minimum 1.5s), then Before we start. A creator account (`emerging`, `established`) sees the edition picker. Personal starts the player. Creator toasts “Not part of this demo”. A return visit reaches card 1 in under 2 seconds, measured inside the app, not by the XCTest tap clock. |
| 14 Info sheet | **Not done.** `CardInfoSheet` is a close button on an empty sheet. No provenance, window, method, “This looks wrong”, or “Hide this card”. Swipe-up opens that empty sheet. |
| 15 Share rendering | Not started. |
| 16 Share to Instagram | Not started. See above. |
| 17 Web landing | Stub only. |
| 18 Hub | Not started. |
| 19 Privacy | Not started. No toggles, no delete, no re-run of `build-run`. “Choose what’s included” on the intro toasts. |
| 20 Remix | Not started. |
| 21 Quality pass | Not done. No perf pass, no VoiceOver audit, no empty/offline pass. |
| 22 Creator edition | Not started. The picker exists. The creator story does not. |
| 23 Together / Guess My Wrapped | Not started. |
| 24 Pitch package | Not done. `build/demo-story.mp4` is a local 71-second recording from before cards 10–13. It is gitignored. It is not the pitch video. |

Reduce Motion is implemented, not audited. Chapter changes crossfade in 150ms. Several card animations skip their motion when Reduce Motion is on. There is no test that walks every card under the setting.

VoiceOver is implemented, not audited. The player exposes Next card, Previous card, magic-tap pause, and escape. XCTest cannot fire custom accessibility actions, so those were not UI-tested. A VoiceOver button test was removed on purpose. Do not add it back.

Teen rules are partial. The engine filters cards 8 and 9 for `is_teen`. The app omits those cards when the profile says teen, and when launched with `--teen`. Ranked circle, DM privacy, and the rest of the teen rules are step 19.

## What the player actually does

Thirteen personal cards. Chapters: Memories 1–2, Interests 3–5, Moments 6–7, People 8–9, Identity 10–13. Durations are 6 seconds, or 9 for cards 2, 10, and 12. Card 11 does not auto-advance. Tap left third goes back. Last card forward exits. Chapter swipe lands on the first included card of the neighbor chapter. Progress is saved on exit to `igwrapped.player-progress`, but `--player` does not resume. Resume-from-banner is “start at card 1”, not “continue where you left off”.

Card 8 has a private lock and no share. Cards 1 and 11 hide the info button. Share pills toast. The personality reveal haptic is `.sensoryFeedback(.success)`.

## Assets the user deferred

Do not draw these. Ask for the files.

- Instagram glyph and wordmark (`Resources/Brand/`, gitignored)
- `maya-profile.jpg`
- `story-0314.jpg`
- Friend headshots (`friend-<name>`). The circle uses `tile-1`…`tile-5`
- Month photos `m-01.jpg`…`m-11.jpg`
- Chapter audio (`Resources/Audio/`, gitignored). Missing audio stays silent

Photos that are bundled: `tile-1`…`tile-5`, `feed-chicago.jpg`, `main-character.jpg`, `year-card.jpg`.

## Fixes worth doing before calling the pitch ready

Replaced by `docs/UPDATE-01.md` section 3 (decision D19). Work that list in order: Batch A (F0–F8), then Step 13.5, Step 14, Step 15, Step 16. Step 17 waits until Step 16 is confirmed on a physical iPhone.

## Questions that were not guessed

- “This looks wrong” reasons are decided in D13: `number_off`, `not_me`, `dont_remember`, `other`. No free text.
- `days_active` (301) stays a metric and is not shown on a card (D14).
- Facebook App ID, and whose Meta app it is.
- A physical iPhone for the Story handoff. The build Mac cannot prove step 16.
- Wordmark, glyph, month photos, story-0314, friend headshots, and audio. The user said to add those files later.
- Creator edition is a later step. The picker toast is a placeholder, not a creator story.
- `DECISIONS.md` was not edited during the build. If a later doc edit disagrees with it, DECISIONS still wins.

## Tests that were green at the end of step 13

On iPhone 17e, iOS 27.2:

- Unit tests, including teen skip, reveal-stops-autoplay, and the entry route table.
- Chapter swipe, reveal lands on card 12, Identity/Numbers toggle.
- Maya claim survives relaunch, against local Supabase.
- Algorithm feedback writes a row and shows the toast only after the insert.
- Banner reaches card 1 in under 2 seconds on a return visit.
- Creator persona `emerging` sees the edition picker, and Personal opens the player.

A CoreUI log line, “unable to find a bundle”, showed up during unit tests and did not fail them.

## What not to “fix” while cleaning up

- Friend-story layout in `IGStoryViewer` only renders text reliably in a center `ZStack` that is then offset. Do not simplify that file.
- `rotation3DEffect` at rest swallows taps. `CubeFace` applies the rotation only while the angle is at least 0.5 degrees.
- Do not put `.accessibilityIdentifier` on a parent that wraps the controls. It overwrites the children’s identifiers. That bug already broke the Start button once.
- Do not `.frame(maxWidth: .infinity, maxHeight: .infinity)` on a button. It becomes full screen and eats the gesture layer.
- Chrome must stay intrinsic height. A full-screen chrome layer eats every tap.
- Config URL must keep `http:/$()/127.0.0.1:54321`.
