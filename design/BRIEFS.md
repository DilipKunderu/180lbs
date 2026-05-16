# Claude Design briefs — Act.

This file is the authoritative source for what to prompt Claude Design with to extend the existing **A · Command** design system. The system is already locked: dark mode, brutalist mono numerics, single lime CTA on black, one imperative word per screen ending in a period.

## How to use this file

1. Open the Act. project in Claude Design at `claude.ai/design`.
2. Pick a brief from below (priority order is listed).
3. Copy the **Prompt** block verbatim into Claude Design chat.
4. Iterate visually until satisfied. Use the Tweaks panel to confirm aesthetic still matches.
5. Export the updated ZIP back to `/Users/dilipkunderu/180lbs/design/180LB.zip` (overwrite). Re-extract.
6. Tell the agent (me, in Cursor): "designed screen N — port to SwiftUI." I'll read the updated JSX and produce the SwiftUI view.

## Design system reminders (always preserve)

- **Background**: `#000000`. Surfaces in `#0A0A0A`, `#141414`, `#1C1C1E`.
- **Text tiers**: 100% / 55% / 32% / 18% white.
- **Lime accent**: `oklch(0.88 0.18 130)` only. No other colors except lava/ice/bone in tweaks panel.
- **Hero word** ends in `.`: "Eat.", "Walk.", "Sleep.", "Hydrate.", "Lift.", "Swim.", "Cook."
- **All numbers in SF Mono.** All words in SF Pro Display. Type scale: 96/84/72/56/44/36/28/24/22/20/18/16/14/13/12/11.
- **No cards.** Naked rows with hairline bottom borders only.
- **Sticky CTA button** at the bottom — 56h, 18r, lime fill, black text, display 18/700.
- **Top status bar** padded `paddingTop: 60` to clear the iOS status bar.
- **Mono tags** at 11–13px with letter-spacing 0.6–1.2, often uppercase.

## Re-prompts for existing screens (do these first)

### R1. Re-prompt `CmdToday` for OMAD

The current Today screen shows "Oats." at 7:24 with breakfast macros — that's multi-meal placeholder data. The real product is OMAD (one meal at 18:00). The Today screen needs many states across the day; this brief is for the **mid-fast daytime state**.

**Prompt:**

> In the Act. design system, update the existing `CmdToday` screen (variation A · Command) to reflect the real product, which is **One Meal A Day (OMAD)**. The eating window is 18:00–19:00 daily. The user is fasted from ~19:00 the previous night until 18:00 the next day.
>
> The Today screen has multiple states. For now, design the **fasted daytime state** (visible from ~7:30 after the morning gym block until 17:30):
>
> - Time top-left in SF Mono at 13px: "11:42"
> - Hero word: `Fast.` (display 84, weight 800, letter-spacing -3.5)
> - Below the hero, a giant countdown timer in SF Mono Display: "06:18:04" until 18:00 (display 72, weight 700, mono digits, letter-spacing -2)
> - Caption under the countdown in mono 13px / textMute: "until eat"
> - Below: a full-width continuous hydration progress bar, 4pt tall, 2pt corner radius. Track is hairline (`rgba(255,255,255,0.06)`), fill is lime at 30% (36 oz of 120 oz target). Label below the bar in mono 13: `Hydrate · 36 / 120 oz`. Match the metaphor of the Live Activity expanded `Row 2` exactly — no segmented ring on this surface.
> - At the bottom of the content area, naked rows showing today's remaining checks: a row each for "Lift" (struck through, opacity 0.35 — already done), "Swim" (struck through), "Walk" (faint, pending), "Sleep" (faint, pending). Mono 13 time on left, display 20 word on right.
> - Sticky CTA at bottom: black surface with hairline border (NOT lime — there's no action to take during the fast). Text: "Drink water" mono 13 / textDim. Tapping this opens a hydration log sheet.
>
> Keep all colors, type, and spacing tokens identical to the existing design system. Make the countdown the visual hero.

### R2. Re-prompt `CmdWorkout` for Full Body Day A

The current workout screen shows "Bench. 185 × 5" which is from a Push/Pull/Legs split. The real program is 3-day Full Body, alternating Day A / Day B.

**Prompt:**

> Update the existing `CmdWorkout` screen in variation A · Command to use the real lift program: **3-day Full Body**, alternating Day A and Day B.
>
> Today is **Day A**, consisting of: Squat 3×5, Bench 3×5, Row 3×5, Plank 3×30s, Face Pull 3×12. (Day B will be a separate screen — design it as a copy with different lifts: Deadlift 1×5, OHP 3×5, Lat Pulldown 3×8, RDL 3×8, Tricep Pushdown 3×12.)
>
> The user is currently on **lift 2 of 5 (Bench)**, **set 2 of 3**. Elapsed: 22:14. The hero number is the work weight: **135 lb × 5 reps** (display 88, weight 800, mono numbers, letter-spacing -3.5). 135 lb is a plausible mid-program working weight (~11 weeks of +2.5 lb linear progression from the seeded 95 lb starting bench). The previous 185 from the placeholder design was too aggressive for this program — do not reintroduce it.
>
> Update the progress bar at top to show 5 segments (one per lift), where lifts 1 (Squat) is full lime, lift 2 (Bench) is lime-dim (in progress), lifts 3-5 (Row, Plank, Face Pull) are hairline.
>
> The "3 / 6" label at top-left should become "2 / 5".
>
> Keep the rest of the layout (swap button + Done button at bottom, mono tag below the number) identical.
>
> Also produce a second artboard for **Day B**: hero "Deadlift.", weight 185 lb × 5, 1 of 5 lifts, set 1 of 1 (deadlift is a single heavy set), rest 3:00. 185 lb is a plausible mid-program working weight (~10 weeks of +5 lb linear progression from the seeded 135 lb starting deadlift).

### R3. Re-prompt `CmdCook` to remove recipe content (Sunday orchestrator only)

The current "Sear." screen contains explicit cooking instructions — that's wrong. The user owns their recipes in Paprika / NYT Cooking. Act. is an **orchestrator** for the Sunday session: timer, phase progress, recipe link out. **No cooking steps, no cook verbs, no ingredient lists.**

**Prompt:**

> Strip recipe content from the existing `CmdCook` screen in variation A · Command. Act. does not contain recipes — the user keeps recipes in Paprika / NYT Cooking. This screen is purely the Sunday batch session **orchestrator**.
>
> Top: mono 11 uppercase letter-spaced 1.2 textMute: `SUNDAY COOK · 14:00`
>
> Replace the existing rotating hero ("Sear.") with a **single fixed hero word across all 5 phases**: `Cook.` (display 84, weight 800). The hero never changes during the session — it's the same on every phase.
>
> Replace the existing substep list ("Heat pan medium-high · oil · salmon skin-side down...") with **nothing**. There are no substeps. There is no cook-method text. There are no ingredient lists. This screen never tells the user how to cook.
>
> Below the hero, three naked-row blocks (no cook content):
>
> *Row A — Current phase:*
> Mono 11 uppercase letter-spaced textMute: `PHASE 3 / 5`. Below it, display 28 weight 700: a high-level phase name from this list: `Prep` / `Sauces` / `Proteins` / `Portion` / `Wrap`. (These are organizational categories, not cooking instructions.)
>
> *Row B — Phase timer:*
> The existing circular timer (88×88 lime ring), but with mono display 44 weight 800: the *elapsed* time for the current phase, e.g. `28:14`. Below in mono 12 textMute: `phase elapsed`. No countdown — just elapsed time. The user moves on when they're done, not when a timer expires.
>
> *Row C — Recipe link (when configured):*
> If the user has a recipe URL configured for any of this week's dishes, a single naked row: mono 11 uppercase textMute "RECIPES" header, then up to 2 display 16 lime rows like `Salmon coconut curry →` and `Beef chili →`. Tapping deep-links to Paprika / NYT Cooking. If no URLs configured, this row is hidden entirely.
>
> Below the rows, a 5-segment progress bar (same pattern as `CmdWorkout`): phases 1–2 full lime, phase 3 lime-dim (in progress), phases 4–5 hairline.
>
> Sticky CTA: a single full-width lime "Next phase." button. Display 18 weight 700. The button advances to phase 4 and resets the elapsed timer. After phase 5 it becomes "Done." (display 18 weight 800) and ends the session.
>
> Match all design tokens. **No cook verbs, no substeps, no ingredients, no cook times.** The app does not know how to cook; the user does.

### R4. Re-prompt `CmdProgress` with real starting weight

The progress screen is largely correct. Just update the weight numbers from a 200 → 184 trajectory to a **308 → goal 180** trajectory.

**Prompt:**

> Update `CmdProgress` in variation A · Command. The user starts at **310 lb** and targets **180 lb**. Currently at **308 lb** (week 1, just 2 lb down from peak). Update the chart points to start at 310 and trend gently down to 308, with goal line at 180. The big hero number is now **308** (not 184). The mono caption updates to `−2 · 128 to go`. Adherence 94%, Streak 23, Sleep 7.4h, Protein 6/7 all stay. Week dots: today is Wednesday, M/T already complete. Keep everything else identical.

## New screens (priority order for v1)

### 1. Today — Pre-workout (lift days only)

**Purpose**: Fires at 5:15 on M/W/F. User has just weighed in, drunk water + sodium, taken caffeine + creatine. Time to leave for the gym.

**Prompt:**

> Add a new screen `CmdPreWorkout` to variation A · Command in the Act. design system.
>
> Time top-left mono 13: "5:15"
> Hero word: `Lift.` (display 84, weight 800, letter-spacing -3.5)
> Sub-line in display 24 / textDim: "Day A · 5 lifts · 50 min"
> Below in mono 13 / textMute, three naked rows:
> - "Water" — `✓` (lime check icon) — 24oz done
> - "Sodium" — `✓` — 1g done
> - "Caffeine + creatine" — `✓` — done
>
> The body otherwise empty. The point is psychological readiness, not data.
>
> Sticky CTA: lime "Start" button (full-width 56h 18r).
>
> Use the existing `Icon.check` from `shared.jsx`.

### 2. Today — Hydration moment (Layer 2 Firm, three states)

**Purpose**: Hydration is the user's stated weakness, so this gets accountability treatment: hardware truth source (Hidrate Spark PRO bottle), 120 oz daily target, reactive escalation when stale. Three visual states tied to staleness: **on-pace (lime)**, **warn (amber, 30 min stale)**, **critical (lava + haptic, 60+ min stale)**.

**Prompt:**

> Add three artboards for `CmdHydration` to variation A · Command, each representing one staleness state. They share layout but differ in color and tone.
>
> **All three artboards share:**
> - Time top-left mono 13: "12:00"
> - Hero word: `Hydrate.` (display 84, weight 800)
> - Below the hero, a giant circular ring at 240×240. Inside the ring in mono display 80 weight 800: current oz like `84` (no "/120"). Below the number inside the ring, mono 14 textMute: `oz · 70%`
> - The ring fills clockwise to match the percentage of 120 oz target
> - Hairline track (`rgba(255,255,255,0.06)`), accent stroke is the staleness color
> - Below the ring, mono 13 letter-spaced uppercase: a single line of context that changes per state
> - Sticky CTA: 56h 18r button, full-width
> - Sub-CTA above the sticky button, centered mono 13 textDim: "Logged 12oz manually" (fallback for when bottle isn't present)
>
> **Artboard A — On pace (lime, default):**
> - Ring stroke: `oklch(0.88 0.18 130)` (lime)
> - Caption under ring: `NEXT SIP · 22 MIN` in mono 11 textMute letter-spaced 0.8
> - CTA: lime background, black text "Logged"
>
> **Artboard B — Warn (amber, 30+ min stale):**
> - Ring stroke: `oklch(0.78 0.16 60)` (amber)
> - Caption: `LATE BY · 32 MIN` in mono 11 amber letter-spaced 0.8
> - CTA: amber background `oklch(0.78 0.16 60)`, black text "Drink now"
> - Add a single warning glyph (Icon.flame or similar from shared.jsx) inline before "LATE BY"
>
> **Artboard C — Critical (lava, 60+ min stale):**
> - Ring stroke: `oklch(0.68 0.22 25)` (lava red-orange)
> - Caption: `LATE BY · 1H 12M` in mono 11 lava letter-spaced 0.8
> - CTA: lava background, black text "DRINK NOW" (uppercase, weight 800, letter-spacing 1)
> - The hero word changes from `Hydrate.` to `Drink.` for stronger imperative
> - Below the hero, an additional small caption display 16 textDim: "You are 3 sips behind."
>
> Match all other design tokens to the existing system. Do not introduce new colors beyond the three staleness colors already defined.

### 3. Today — Reheat cue (17:30)

**Purpose**: 30 min before the meal window opens. The week's prescribed dish surfaces. User opens the fridge, microwaves the prepped container.

**Prompt:**

> Add a screen `CmdReheat` to variation A · Command.
>
> Time top-left mono 13: "17:30"
> Hero word: `Reheat.` (display 72, weight 800, letter-spacing -3)
> Below, an imagery placeholder (use the existing `Placeholder` component, height 200, radius 18, label "SALMON COCONUT CURRY").
> Below the placeholder, mono macros row (mirror the existing `CmdToday` macros pattern): `2150 kcal · 190 P · 230 C · 60 F`.
> Below the macros in display 14 textDim: "Container 1 · fridge" (location only — no heating method, no minutes, no instructions)
>
> Sticky CTA: a single lime "Start meal." button. No second CTA, no "Open recipe" link on this screen. The user knows how to reheat their own food; the app's job is to tell them *what* to eat tonight, not *how* to heat it.

### 4. Today — Meal window open (18:00)

**Purpose**: Fires at 18:00. Eat the prescribed meal. One tap to log + shake.

**Prompt:**

> Add a screen `CmdMeal` to variation A · Command.
>
> Time top-left mono 13: "18:00"
> Hero word: `Eat.` (display 84, weight 800)
> Below the hero, a single naked row showing today's dish: display 28 left "Salmon coconut curry"; mono 14 right "2150 kcal".
> Below that row, three more naked rows for the meal components:
> - "Protein · salmon 16 oz · 95g" (display 16 / mono 13)
> - "Shake · whey 30g · 30g" (display 16 / mono 13)
> - "Carbs · rice 2c · 90g" (display 16 / mono 13)
>
> Bottom of screen, a small mono 11 line: `MEAL WINDOW · 18:00 – 19:00 · 14m left until reset`
>
> Sticky CTA: lime "Logged + shake" full-width button (display 18 / 700).
> Secondary smaller text-only button above the CTA, centered, mono 13 textDim: "Deviated →" (opens the deviation flow with photo + reason picker)

### 5. Today — Post-meal walk (19:00)

**Purpose**: 20-min walk to aid glucose response. Auto-tracks via HealthKit.

**Prompt:**

> Add a screen `CmdWalk` to variation A · Command.
>
> Time top-left mono 13: "19:00"
> Hero word: `Walk.` (display 84, weight 800)
> Below the hero, a large countdown ring (similar to `CmdCook` timer): 88×88 ring with lime stroke at 0% (just starting). To the right in display 44 weight 800 mono: `20:00`. Below in mono 13 textMute: `min`.
> Below the timer row, mono 11 letter-spaced uppercase: `AUTO-LOGGED · HEALTHKIT`
>
> Sticky CTA: lime "Start" full-width.

### 6. Today — EOD (21:00)

**Purpose**: 30 min before bedtime. Lights-out warning. Also the daily smoke-check moment.

**Prompt:**

> Add a screen `CmdEOD` to variation A · Command.
>
> Time top-left mono 13: "21:00"
> Hero word: `Sleep.` (display 84, weight 800)
> Below the hero, in display 20 textDim: "Lights out in 30m"
> Four naked rows (today's completed checks):
> - "Weight" — mono 14 right: `308.4 ▼0.6`
> - "Lift" — mono 14 right: `✓ Day A · 50m`
> - "Meal" — mono 14 right: `✓ 2150 kcal · 192 P`
> - "Smoke" — mono 14 right: `◯ check` in lime (this row is interactive — tappable)
>
> The smoke row defaults to a hairline-outlined empty circle "◯" and the mono text "check" in lime. When the user taps the row, it expands inline into two large buttons that take the full row width:
> - Left (lime fill, black text, display 18/700): `Clean.`
> - Right (surface2 with lava-tinted hairline border, lava text, display 18/700): `Log relapse.`
>
> Tapping `Clean.` collapses the row to show `✓ Clean · day 47` in lime mono 14, increments the clean streak by 1, and the row goes inactive.
> Tapping `Log relapse.` opens the relapse log sheet (`CmdRelapse`, brief 20).
>
> Sticky CTA: lime "OK" full-width button. Tapping schedules a Do Not Disturb activation at 21:30. Note: the CTA is disabled until the smoke row has been answered (one or the other). This is the only forced choice in the whole app — you cannot end the day without answering the smoke question.

### 7. Today — Weigh-in (5:00 wake)

**Purpose**: First screen the user sees. Weight already passively logged from Withings; this is the acknowledgement.

**Prompt:**

> Add a screen `CmdWeighIn` to variation A · Command.
>
> Time top-left mono 13: "5:00"
> Hero word: `308.4` (display 120, weight 800, letter-spacing -5, **all numeric** since this is a number-only hero — no period, no word)
> Below the number, mono 16 letter-spaced uppercase: `LB · ▼ 0.6 · 7-DAY AVG 309.1`
> Below that, a tiny inline sparkline of the last 7 days' weights (height 40, width 100% minus padding, lime stroke 0.8pt, no fill, mono 11 axis labels at start and end: `Wed · Tue`).
>
> Sticky CTA: lime "Good." full-width button. (Yes, the button says "Good." — that's the imperative response to the weight, on-brand.)

### 8. Swim — lift day 30 min recovery

**Purpose**: After lift on M/W/F. Low-intensity laps for active recovery.

**Prompt:**

> Add a screen `CmdSwim` to variation A · Command.
>
> Time top-left mono 13: "6:45"
> Hero word: `Swim.` (display 84, weight 800)
> Sub-line display 24 / textDim: "Recovery · 30 min · Zone 2"
> Below, large countdown ring at 240×240 (same pattern as the meditation/Hydration ring): hairline track, lime arc growing. Inside the ring, mono display 80 weight 800: `0:00` (will animate to 30:00). Below the ring in mono 13 textMute: `HR target 120–135`
>
> Sticky CTA: lime "Start" button.
>
> Also add a second artboard `CmdSwimSolo` identical to this but with: sub-line "Solo · 60 min · Zone 2/3", 60-min countdown, HR target "120–145".

### 9. Live Activity — Compact (Dynamic Island) and Expanded (with hydration + cessation accountability)

**Purpose**: The lock-screen surface that persists all day. Must show meal countdown (hero), hydration state (secondary, rich), and clean-streak (third row, lime — or lava for 24h after relapse).

**Prompt:**

> Design Live Activity layouts for Act. with **three compact variants** and **two expanded variants** (normal day and relapse-day).
>
> **Compact A — Default (Dynamic Island, leading + trailing):**
> Leading region: lime dot + mono 11 letter-spaced "ACT"
> Trailing region: mono 13 white "6:18" (hours-minutes countdown to meal at 18:00)
>
> **Compact B — Hydration emergency (replaces Compact A when hydration is 60+ min stale):**
> Leading region: a single lava-colored droplet icon
> Trailing region: mono 13 lava-colored, slow pulse animation: "DRINK"
> The meal countdown DISAPPEARS until a sip is logged.
>
> **Compact C — Relapse day (replaces Compact A for 24 hours after a relapse is logged):**
> Leading region: a small lava-colored circle outline (broken-streak icon)
> Trailing region: alternates every 5 seconds between mono 13 white "6:18" (the normal meal countdown) and mono 13 lava "RESTART · 0". The alternation is the surface that you cannot dismiss.
> Compact C takes priority over Compact B — if both a hydration emergency and a relapse day are active, the user sees the relapse alternation (relapse is the more important accountability moment).
>
> **Expanded — Normal day (390×160 dark surface `#0A0A0A`, 24pt radius):**
> A 4-row layout:
>
> *Row 1 — Meal countdown (hero):*
> Mono 11 uppercase letter-spaced 1.2 textMute "UNTIL EAT". Below it display 56 weight 800 mono "06:18:04".
>
> *Row 2 — Hydration progress (secondary):*
> Drop icon in staleness color · mono 14 "84 oz / 120 oz" · mono 11 textMute right-aligned: "NEXT SIP · 22 MIN" (lime), or "LATE 32 MIN" (amber), or "LATE 1H 12M" (lava). Below: a full-width 4pt progress bar in staleness color.
>
> *Row 3 — Clean streak (third row):*
> Left: small lime broken-circle icon (◯). Beside it mono 14 weight 600 lime: "CLEAN · 47 / 365 days". Right side mono 11 textMute letter-spaced: "RECOVERY · DAY 47".
> Tap = open RecoveryView. Long-press = open relapse log (deliberate friction).
>
> *Row 4 — Today's 4 checks:*
> Horizontal row of 4 mono 12 status items separated by `·`: "Weigh ✓" / "Lift ✓" / "Swim ✓" / "Walk ○".
>
> **Expanded — Relapse day (active for 24 hours after a logged relapse):**
> Same layout as Normal but with these overrides:
> - A 2pt lava-colored border around the entire 24pt-rounded surface
> - Row 3 (clean streak) replaces the lime icon with a lava broken-arc, replaces text with mono 14 weight 600 lava: `RESTART · day 1 begins tomorrow`. The right-side recovery label disappears.
> - All other rows (meal countdown, hydration, today's checks) remain functional — the rest of life doesn't stop.
> - Surface background remains `#0A0A0A` (don't tint the whole surface; only the border).
>
> Lock-screen full layout = Expanded layout. Same for both normal and relapse states.
>
> Match all existing design tokens. Accent colors: lime (default), amber (hydration warn30), lava (hydration critical / relapse 24h state).

### 10. Widgets — Small / Medium / Large

**Purpose**: Home Screen widgets.

**Prompt:**

> Design three Home Screen widget sizes for Act.
>
> **Small (170×170):**
> Black background, 18px corner radius. Centered display 32 weight 800 mono countdown: "6:18". Below it in mono 9 textMute letter-spaced uppercase: "UNTIL EAT". Bottom-left lime dot (Act. logo mark). Bottom-right tiny mono 9 "308.4 LB".
>
> **Medium (350×170):**
> Same black surface. Left half: the small widget contents. Right half: a 4-row vertical naked-row stack with mono 11 status for Weight / Lift / Swim / Walk — show today's check marks. Below it, the 3-segment hydration bar in mono 11.
>
> **Large (350×370):**
> Top: same hero countdown as small (centered, display 56). Below: a 6-row vertical timeline of today's plan (Weight 5:00 ✓ / Lift 5:30 ✓ / Swim 6:45 ✓ / Hydrate 9–15 1/3 / Eat 18:00 ○ / Sleep 21:30 ○) — each row mono time + display word + mono status. Bottom: macro row in mono showing 0 / 2150 kcal · 0 / 190 P (since fast = nothing eaten yet).
>
> All three widgets share the same dark surface, same tokens.

### 11. Onboarding flow (9 screens)

**Prompt:**

> Design a 9-screen onboarding flow for Act. in variation A · Command. Each screen has the same skeleton: black background, hero word, brief sub-line, single CTA at bottom.
>
> 1. Welcome: hero "Act." (display 120, weight 800, letter-spacing -5). Sub-line display 20 textDim: "No menus. No choices." CTA "Begin".
> 2. Profile: hero "You." display 84. Naked rows: Height 6'0" / Sex M / Age 33 / Weight 310 lb / Goal 180. All editable. CTA "Confirm".
> 3. Health: hero "Health." Sub-line display 20 textDim "Connect Apple Health". A naked-row list of what we'll read (weight, steps, sleep, **resting HR, HRV, VO2 max**) and write (workouts, dietary energy, dietary water). CTA "Allow".
> 4. Notifications: hero "Push." Sub-line "7 a day. Useful ones." Naked rows showing the daily schedule (5:00 weigh-in / 5:15 pre-workout / 7:00 post-workout 16oz / 17:30 reheat / 18:00 eat / 19:00 walk / 21:00 sleep). CTA "Allow".
> 5. Scale: hero "Weigh." Sub-line "Pair a smart scale." Show two paths: "I have Withings/Eufy/Renpho" (CTA primary) vs "Manual for now" (secondary mono link).
> 6. Hydration: hero "Sip." Sub-line "Pair a Hidrate Spark PRO." Three rows: "Already paired in Apple Health" (CTA primary, lime) / "Buy one ($65)" (link to hidratespark.com) / "Manual taps for now" (secondary mono link). Below the rows in textDim display 14: "Layer 2 accountability — 120 oz daily, escalating prompts when stale."
> 7. **Quit. (NEW)**: hero "Quit." (display 84, weight 800). Sub-line display 20 textDim: "Today is Day 0. Zero hookah from this moment." Three sections below the hero:
>    - Triggers (multi-select small chips): `Social invitation` `Stress` `Boredom` `After dinner` `Specific person` `Specific place`. Selected chips fill lime with black text, unselected are hairline-outlined with textDim text.
>    - Your why: a single-line text input with mono 14 placeholder "One sentence — why are you quitting?" The text the user types here will resurface during withdrawal moments (days 1–7) as a personal reminder.
>    - External stakes (collapsed, mono 13 textDim link "Add stakes later →"). Tapping shows a tiny note: "Beeminder / social referee available in v2. Not now."
>    
>    Sticky CTA: lime "I am a non-smoker." (the language is identity-based, present-tense, deliberate)
> 8. Rotation: hero "Eat." Sub-line "Week 1 of 4". Naked rows of the 8 dishes (4 weeks × 2 dishes) collapsed; week 1 expanded showing Salmon coconut curry + Beef chili. CTA "Looks good".
> 9. Grocery: hero "Shop." Sub-line "Saturday list, ready." Preview of the week's grocery list categorized (Proteins / Grains / Produce / Dairy / Pantry). CTA "Send to Reminders".
>
> Onboarding is now **9 screens** (added Quit. step 7 between Hydration and Rotation; tracking quit-date as install moment).

### 12. Weight number-pad (manual fallback)

**Prompt:**

> Add a screen `CmdWeightPad` to variation A · Command.
>
> Top: mono 11 uppercase "MANUAL WEIGH-IN"
> Hero: a large display 96 weight 800 mono entry field showing "308._" with a lime cursor blinking
> Sub-line: mono 13 textMute "lb"
>
> Below: a standard iOS number-pad grid (3×4 buttons) with a decimal point button and a backspace. Each button is 80×80, surface2 background, 18 corner radius, display 28 weight 700.
>
> Sticky CTA: lime "Logged" button.

### 13. Meal deviation log (photo + reason)

**Prompt:**

> Add a screen `CmdDeviate` to variation A · Command.
>
> Top: mono 11 uppercase "DEVIATED"
> Hero word: `Off.` (display 72, weight 800)
> Sub-line display 18 textDim: "Photo + reason. Move on."
> Below: a large camera/photo placeholder area (use `Placeholder` component, full width, height 280, label "TAP TO ADD PHOTO").
> Below the photo, four reason options as naked rows (radio-button-like — selected = lime check icon, unselected = empty hairline circle): "Eating out" / "Social event" / "Travel" / "Just didn't follow plan".
> Below the reasons, two mono numeric entry rows: "kcal (est)" / "protein (est)" — each is a tappable inline number entry.
>
> Sticky CTA: lime "Logged" button.
>
> No shame language. No "try again tomorrow" messaging. Just log and dismiss.

### 14. Rotation editor — 4-week × 2-dish grid

**Prompt:**

> Add a screen `CmdRotation` to variation A · Command. This is a settings/editor screen, not an in-the-moment action screen — so it can break the one-imperative-word rule.
>
> Top: mono 11 uppercase "ROTATION · 4 WEEKS"
> Below: a vertical list of 4 week sections. Each week has a display 32 heading "Week 1" and two naked rows showing the Indian dish and the Mexican dish. Each row is tappable to edit.
>
> Week 1: Salmon coconut curry · Beef chili
> Week 2: Cod tikka · Chicken fajita bowl
> Week 3: Mahi vindaloo · Turkey enchilada bowl
> Week 4: Shrimp korma · Pork carnitas bowl
>
> A "Restart cycle" mono 11 button at the bottom, plus a "Add custom dish" lime CTA.

### 15. Weekly review

**Prompt:**

> Add a screen `CmdReview` to variation A · Command.
>
> Top: mono 11 uppercase "WEEK 4 · REVIEW"
> Hero word: `Review.` (display 72)
>
> Body: 4 naked stat rows (display 18 left, mono 18 weight 700 right):
> - Adherence — `94%`
> - Weight change — `−1.8 lb`
> - Lift PRs — `Bench +10 · Row +5`
> - Swim total — `4h 12m`
>
> Below the stats, a dark surface (`surface2`) callout with rounded 18 corners, 24px padding, containing the Apple Intelligence-generated insight + suggested tweak in body text (display 16 / 1.5 line height, color text). At the bottom of the callout, two small buttons: lime "Apply" + mono link "Not now".

### 16. Grocery list

**Prompt:**

> Add a screen `CmdGrocery` to variation A · Command.
>
> Top: mono 11 uppercase "SHOP · SAT · WEEK 1"
> Hero word: `Shop.` (display 72)
>
> Body: categorized naked-row list of the week's groceries. Each category is a mono 11 textMute uppercase header followed by display 16 rows with mono 13 quantity on the right.
>
> Categories: Proteins (salmon 4 lb, ground beef 3.5 lb), Grains + Legumes (basmati rice 4.5 cups dry, kidney beans 2 cans, black beans 2 cans), Produce (cucumber 2, tomato 4, onion 3, cilantro 1 bunch, lime 6, bell pepper 2), Dairy + Eggs (Greek yogurt 1 quart, shredded cheese 8 oz, sour cream 1 cup), Pantry (whey protein, ghee, oil, spices — assume already stocked), Bread + Tortillas (parathas frozen 1 pack, corn tortillas 1 pack).
>
> Sticky CTA: lime "Send to Reminders" full-width button.

### 17. Settings

**Prompt:**

> Add a screen `CmdSettings` to variation A · Command. Settings can break the one-imperative-word rule.
>
> Top: mono 11 uppercase "SETTINGS"
> No hero word.
>
> Body: vertical naked-row list grouped into sections (each section has a mono 11 textMute uppercase header):
> - Profile: Weight (308.4) / Goal (180) / Daily kcal target (2150) / Protein target (190g)
> - Schedule: Wake (5:00) / Meal window (18:00–19:00) / Bed (21:30)
> - Notifications: edit times / enable/disable each
> - Pause: Sick mode / Travel mode toggles
> - Recipes: paste Paprika/NYT Cooking URLs per dish
> - Data: Export JSON / Reset week
>
> Each row tappable to open an inline editor.
>
> No CTA at bottom (this is a hub).

### 18. Urge log (`CmdUrge`) — one-tap craving + 5-min breathing

**Purpose**: Fast escape hatch for when the user feels a hookah craving but does NOT smoke. Logged for pattern data; no shame, no streak impact. Tappable from any Today screen via a small lime droplet/smoke icon in the corner.

**Prompt:**

> Add a screen `CmdUrge` to variation A · Command, presented as a sheet (modal slide-up, not a full-screen replacement).
>
> The sheet is 80% of screen height, dark surface `#0A0A0A` with rounded 24pt top corners.
>
> Top: mono 11 uppercase letter-spaced 1.2 textMute "URGE LOGGED · NO SHAME"
> Hero word: `Breathe.` (display 84, weight 800)
> Sub-line display 18 textDim: "5 minutes. Then it passes."
>
> Below the hero, a large animated breathing circle (240×240). The circle expands and contracts on a 4-7-8 pattern: 4 sec inhale (circle grows to 1.0x lime), 7 sec hold (circle holds at 1.0x with subtle pulse), 8 sec exhale (circle shrinks to 0.5x). Inside the circle, mono display 32 weight 700: "INHALE" / "HOLD" / "EXHALE" depending on phase, lime color.
>
> Below the circle, mono 13 letter-spaced textMute: "CYCLE 2 / 16" (the counter increments through ~16 cycles to total 5 min).
>
> A small naked-row beneath asks: intensity slider (0–10 dots in a horizontal row, current value lime, rest hairline). User taps the corresponding dot. Default 5.
>
> Three "what's the trigger" chips below the intensity, multi-select: `Social invitation` `Stress` `Boredom` `Smell` `Near a lounge` `Other`. Same chip style as onboarding.
>
> Sticky bottom CTA pair (two buttons side-by-side, 50/50 width):
> - Left, surface2 with hairline border, display 18 weight 700 textDim: "Logged" (skips the breathing — just records the urge)
> - Right, lime fill, black text, display 18 weight 800: "Stay 5m"
>
> Tapping `Logged` dismisses the sheet immediately and records the urge as resisted with intensity. Tapping `Stay 5m` runs the breathing cycle to completion then auto-dismisses.
>
> No relapse action on this screen. If the user wants to log a relapse, they have to close this sheet and use the EOD smoke check or long-press the Live Activity CLEAN row. Friction is intentional.

### 19. Relapse log (`CmdRelapse`) — 60-second friction-positive form

**Purpose**: When the user actually smokes, they log it via a deliberately slow multi-step form. The friction itself is the accountability — 60 seconds of typing/tapping vs casually moving on.

**Prompt:**

> Add a screen `CmdRelapse` to variation A · Command. This is a full-screen modal, not a sheet — it deserves the full surface.
>
> Top: mono 11 uppercase letter-spaced 1.2 lava color: "RELAPSE LOG · 60 SEC"
> Hero word: `Honest.` (display 72, weight 800)
> Sub-line display 16 textDim: "No shame. Just data. Tell me what happened."
>
> Body is a vertical scroll of 7 form rows, each a naked-row block with hairline bottom border, mono 11 uppercase letter-spaced label, and an input control. Spacing 24pt between rows.
>
> Row 1 — Trigger (single-select chip group):
> Label: "WHAT TRIGGERED IT"
> Chips: `Social invite` `Stress` `Boredom` `Ritual` `Specific person` `Specific place` `Other`. Selected = lime fill black text.
>
> Row 2 — Where (text input):
> Label: "WHERE"
> Mono 16 placeholder: "Cafe / friend's place / car..."
>
> Row 3 — Who (text input):
> Label: "WHO WITH"
> Mono 16 placeholder: "Names or 'alone'"
>
> Row 4 — How much (number + unit toggle):
> Label: "HOW MUCH"
> Mono display 32 number entry (default 1) with two pill toggles below: `bowls` / `minutes`. Selected pill lime, other hairline.
>
> Row 5 — Pre-feeling (3 dot-sliders):
> Label: "BEFORE"
> Three rows, each a label + 0–10 dot slider:
> - "Stress" — dots
> - "Craving" — dots
> - "Social pressure" — dots
>
> Row 6 — Post-feeling (2 dot-sliders):
> Label: "AFTER"
> - "Satisfaction" — dots
> - "Regret" — dots
>
> Row 7 — Reflection (single-line text):
> Label: "WHAT YOU'D DO DIFFERENTLY"
> Mono 16 placeholder: "One sentence. Not optional."
>
> Sticky bottom: a single lava-bordered "Submit" CTA, surface2 background, lava text, display 18 weight 800. NOT lime — this is not a celebration. The button is disabled until all 7 rows have a value.
>
> Above the CTA, mono 11 textMute letter-spaced: "Streak will reset to 0. 24-hour lava state on Live Activity. Recovery clock continues."
>
> No animations, no haptics on submit. Just the form acceptance. The user returns to their normal Today screen, which now shows the relapse state.

### 20. Recovery milestones (`CmdRecovery`) — body recovery timeline + HR/HRV/VO2

**Purpose**: Positive reinforcement screen. Shows what's regenerating in the user's body. Pulled from medical literature for hookah/nicotine cessation. Also surfaces HealthKit data (resting HR, HRV, VO2) with pre-quit baseline vs current trend.

**Prompt:**

> Add a screen `CmdRecovery` to variation A · Command.
>
> Top: mono 11 uppercase letter-spaced 1.2 textMute "RECOVERY"
> Hero: display 84 weight 800 lime number — current clean-day count, e.g. `47`. Below the number, mono 13 textMute letter-spaced: "DAYS · 365 TARGET"
>
> Body — two sections, scrollable:
>
> *Section A — Body milestones (vertical timeline, naked rows):*
> Mono 11 uppercase header "BODY"
> Each row is a milestone day + what regenerated. Current day's row is lime; past milestones are textDim with `✓`; future milestones are textFaint.
> - Day 1 — CO normalized
> - Day 2 — Nicotine cleared. Taste returning.
> - Day 3 — Withdrawal peak. The worst day.
> - Day 7 — Lung function measurably improved.
> - Day 30 — Cilia regenerating.
> - Day 90 — Cardiovascular markers significant.
> - Day 365 — Heart attack risk halved.
> - Day 1825 — Lung cancer risk halved.
>
> Each row: mono 13 day-label-left, display 16 text middle, optional lime check icon right.
>
> *Section B — HealthKit trend (3 stat blocks side by side):*
> Mono 11 uppercase header "BODY DATA · FROM APPLE HEALTH"
> Three columns, equal width, each a stat block:
> - Resting HR: pre-quit baseline mono 11 textDim "78 bpm", giant current value display 56 weight 800 mono lime "71", below "▼ 7 bpm" mono 13 lime
> - HRV: pre-quit "32 ms", current "41 ms", "▲ 9 ms" lime
> - VO2 max: pre-quit "24.2", current "26.1", "▲ 1.9" lime
>
> If HealthKit has insufficient data (Watch not worn), the stat shows mono 11 textFaint "no data yet — wear your Watch on training days."
>
> No CTA. This is a read-only screen. User dismisses with the standard iOS back gesture.

### 21. Withdrawal card (`CmdWithdrawal`) — days 1–7 special state with Day 3 hardcoded

**Purpose**: Days 1–7 after quit date are the hardest. The withdrawal companion fires extra prompts and shows the user where they are in the withdrawal curve. Day 3 has hardcoded text: "today is the worst day."

**Prompt:**

> Add a screen `CmdWithdrawal` to variation A · Command. This appears as an opt-in card on the Today screen during days 1–7 only (not after). Tapping the card opens the full screen.
>
> The full screen:
>
> Top: mono 11 uppercase letter-spaced 1.2 lima color: "WITHDRAWAL · DAY 3 / 7"
> Hero word: `Today.` (display 84, weight 800)
> Sub-line display 24 textDim: "is the worst day."
> Below the sub-line, display 18 text (not textDim — full white): "Tomorrow is easier. Day 4 onward, withdrawal tapers."
>
> Below this hero block, a vertical naked-row stack showing the curve qualitatively. Each row is a day with a label + what to expect. Day 3 row is highlighted (lime hairline frame around just that row, lime mono day number). Others are textDim.
> - Day 1 — Nicotine cleared. Mild irritability.
> - Day 2 — Concentration drop. Energy low.
> - Day 3 — Worst day. Cravings peak. (HIGHLIGHTED if current)
> - Day 4 — Cravings less frequent, longer.
> - Day 5 — Sleep improving.
> - Day 6 — Energy returning.
> - Day 7 — End of acute withdrawal.
>
> Below the curve, a "Your why" callout (surface2, 18pt radius, 24pt padding): mono 11 uppercase textMute letter-spaced "YOUR WHY". Below it, display 16 the user's quoted personal "why" sentence from onboarding (italic, line height 1.5).
>
> Sticky CTA: lime "Keep going." full-width button. Tapping closes the screen.
>
> Per day, the hero word changes:
> - Day 1: `Day 1.`
> - Day 2: `Heavy.`
> - Day 3: `Today.` (with "is the worst day" sub-line — fully written above)
> - Day 4: `Lighter.`
> - Day 5: `Sleep.`
> - Day 6: `Energy.`
> - Day 7: `Through.`
>
> The "Your why" callout appears on every day. The withdrawal curve highlights the current day's row.
>
> Bonus: small mono 11 textFaint footer "After day 7, this screen retires. Recovery milestones take over."

## Anti-patterns — what to never let Claude Design produce

- Multiple colors. Lime only. (Lava/ice/bone are tweaks panel alternates, not additions.)
- Cards / shadows / elevated surfaces in the body. Only hairline rows.
- Light mode. Dark only in v1.
- Emoji. Use icons or words.
- Streak badges. Streaks in the design (`Streak 23` in `CmdProgress`) are a stat, not a gamification surface — they don't pulse or animate or shame.
- Generic stock content. Every number should be real (or labeled as a placeholder in a mono tag at top of the artboard).
- More than one CTA per screen. The sticky lime button is the only call to action; secondary actions are mono text links.
- **Cessation language**: never use "slip," "moment of weakness," "it's okay," "try again tomorrow," "you got this." The voice is matter-of-fact: "Honest." "No shame. Just data." "Tomorrow is easier." The user picked in-app-only accountability; the app cannot soften the consequence or it betrays that choice. Equally, never use trophies, badges, streak fireworks, or congratulatory animations on clean-day milestones. The recovery screen is informational, not celebratory.
- **Recipe content**: the app **never** contains cooking instructions, cook methods, cook verbs as hero words (no "Sear.", "Marinate.", "Brown.", "Bake."), ingredient lists with quantities, cook times, temperatures, or step-by-step directions. The user keeps recipes in Paprika / NYT Cooking / Mealime — those apps own the *how*. Act. only orchestrates the *what* (dish name + macros) and the *when* (phase progression + elapsed time). Reheating instructions ("3 min microwave," "350°F oven") also forbidden — the user knows how to heat their own food. The single exception: a tappable "Recipe →" link that deep-links out to the user's external recipe URL when configured.
