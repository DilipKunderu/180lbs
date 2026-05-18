---
version: 1
created_at: 2026-05-17
created_by: user (pre-skill canonization)
changelog_vs_previous: |
  Initial canonization. This repo had a complete product design before the
  pair-programming skill's design-doc lifecycle was introduced; v1 adopts
  the existing assets as the source of truth without rewriting them.

  Adopted assets:
  - design/BRIEFS.md — UX briefs, copy contracts, layout rules, anti-patterns.
  - design/180LB_extracted/ — variation A · Command screen exports (JSX) plus
    onboarding, Live Activity, and widget surfaces. The locked UI.
  - design/180LB_extracted/Act.html — the design canvas index that ties every
    artboard to its component.

  Future revisions land in design.v2.md (and so on). Existing assets remain
  in their original locations as referenced material; they will not move.
---

# Act. product design — v1

This is the canonical product specification for the 180lbs Act. iOS coach. It is the single source of truth that every plan and every implementation must cite and remain consistent with. When this design changes, a new immutable version file is authored (`design.v2.md`, etc.) and the [CURRENT](CURRENT) pointer is updated; this file is never modified in place.

## How to read this version

v1 is an index, not a self-contained spec. The substantive content lives in the existing 180lbs design assets, which v1 adopts wholesale:

- [`../../design/BRIEFS.md`](../../design/BRIEFS.md) — the authoritative UX briefs. Read top-to-bottom for the product voice, copy contracts, layout rules, and anti-patterns. Every screen and every push notification in the app conforms to these briefs.
- [`../../design/180LB_extracted/`](../../design/180LB_extracted/) — the locked UI. Variation A · Command is shipped; B and C exist in the canvas as exploration only and are not in scope.
  - [`components/shared.jsx`](../../design/180LB_extracted/components/shared.jsx) — global tokens: `ACT` color palette (oklch lime/warn/red), `TYPE` font stacks (SF Pro Display / SF Pro Text / SF Mono), icon set, `Placeholder`, `Tag`, `ScreenChrome`.
  - [`components/variation-a-onboarding.jsx`](../../design/180LB_extracted/components/variation-a-onboarding.jsx) — the 9-step onboarding flow (`OnbWelcome`, `OnbProfile`, `OnbHealth`, `OnbNotifications`, `OnbScale`, `OnbHydration`, `OnbQuit`, `OnbRotation`, `OnbGrocery`).
  - [`components/variation-a-command.jsx`](../../design/180LB_extracted/components/variation-a-command.jsx) — the 24 main screens (`Cmd*`). Every per-moment, hydration, cessation, cook, rotation, grocery, deviate, progress, review, and settings surface.
  - [`components/variation-a-live.jsx`](../../design/180LB_extracted/components/variation-a-live.jsx) — Dynamic Island + Live Activity (`LACompactA/B/C`, `LAExpanded`, `LAExpandedRelapse`). The `*Board` wrappers in this file are design-canvas chrome and DO NOT ship.
  - [`components/variation-a-widgets.jsx`](../../design/180LB_extracted/components/variation-a-widgets.jsx) — Home / lock-screen widgets (`WidgetSmall`, `WidgetMedium`, `WidgetLarge`). `WidgetsBoard` is canvas chrome and DOES NOT ship.
- [`../../design/180LB_extracted/Act.html`](../../design/180LB_extracted/Act.html) — the design canvas index. The intro artboard (`id="intro"`, lines 111–134) is canvas chrome (CONCEPT tag, marketing tagline, A/B/C variation descriptions) and DOES NOT ship.

## Hard lines (forwarded from BRIEFS.md, restated here so they're grep-able)

- **Native iOS** only (SwiftUI on iOS 17.4+). No PWA, no web stack, no service worker, no web-push. APNs replaces VAPID.
- **OMAD**, not 3 meals. One meal between 18:00 and 19:00 (configurable in `profile.meal_window_*`). No breakfast / lunch / dinner concepts anywhere in the schema or UI.
- **One imperative per moment**, not one card. Each moment of the day has its own full-screen view; the Today coordinator selects which view to show. No dashboards, no menus, no lists longer than two fields.
- **Cessation pillar is enforced.** The EOD smoke check (`CmdEOD`) is the only forced choice in the app. The OK CTA is disabled until the smoke row is answered. Clean increments the streak; Log relapse opens the full-screen relapse log.
- **No cessation shame language.** "Honest." / "No shame. Just data." / "Tomorrow is easier." No badges, trophies, fireworks, or congratulatory animations.
- **No streaks-as-gamification.** The streak number is a stat; it does not pulse, animate, or shame.
- **No recipe content in-app.** No cooking instructions, temperatures, cook times, ingredient lists, or cook verbs as hero words. Recipes deep-link to Paprika / NYT Cooking via `rotation.recipe_url`.
- **No reheating instructions.** The user knows how to heat their own food.
- **Single user, TestFlight only.** No App Store distribution, no accounts, no social, no sharing, no leaderboards.

## Source assets that DO NOT ship (design-canvas chrome)

The following exist in the design assets but are Figma-style annotations only. The porter sees them in the JSX and skips them:

- The concept artboard in `Act.html` `DCArtboard id="intro"` (lines 111–134): `CONCEPT · DARK MODE iOS` mono tag, the marketing tagline, and the A/B/C variation descriptions. The canonical "No menus. No choices." line ships only as the `OnbWelcome` sub-line per `BRIEFS.md` brief 11.
- `LACompactsBoard` (`variation-a-live.jsx#L266`), `LAExpandedBoard` (`variation-a-live.jsx#L317`), `WidgetsBoard` (`variation-a-widgets.jsx#L220`) — board wrappers that stack the variants with annotation headers and per-row paragraphs. Port the inner `LACompactA/B/C`, `LAExpanded`, `LAExpandedRelapse`, `WidgetSmall/Medium/Large` directly.
- All `DCSection`, `DCArtboard`, `DCEditable`, `DCPostIt`, `DCFocusOverlay` infrastructure in `design-canvas.jsx` — pan/zoom Figma chrome.
- All `Row` helpers inside the Board wrappers — annotation layout.
- All artboard backdrop styles that exist purely to make a 360-wide pill visible on a light canvas — the real iOS surface is the Dynamic Island or lock screen.

## Open questions

None as of v1. Open questions surfaced by future drift-checks land in v2+ frontmatter.

## What v2 will look like

When this design changes (e.g., a new product behavior is introduced, an existing screen is restructured, a hard line is relaxed or tightened), the architect authors `design.v2.md` via `/design-revise <reason>`. That file MUST:

- Carry a `version: 2`, `supersedes: design.v1.md` frontmatter.
- List the substantive changes in `changelog_vs_previous`.
- Be self-contained (a fresh reader uses only v2, not v1).
- Either keep v1's reliance on the existing assets, OR inline the spec if the assets have moved or restructured.

After v2 is written, the orchestrator overwrites [CURRENT](CURRENT) to `design.v2.md`. v1 stays in place, untouched, as the historical record.
