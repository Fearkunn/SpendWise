# SpendWise — Project Instructions

Personal expense tracker: log transactions, organize them by category, set a
monthly budget per category, and see spending visualized against budget.

## Architecture: MVVM, one ViewModel per Model/entity

- One ViewModel per Model/entity type — not per screen. `TransactionViewModel`
  owns CRUD and business logic for `Transaction`; `CategoryViewModel` owns
  CRUD and business logic for `Category` (including budget limits). Each is
  injected into whichever Views need it.
- ViewModels are `@Observable` classes. No `ObservableObject`, no
  `@Published` — plain `var` properties are tracked automatically.
- Views read data via SwiftData's `@Query` directly. ViewModels are the
  write/action layer; they don't hold or expose read state.
- Models are `@Model` classes (SwiftData) — data + relationships only, no
  business logic beyond what SwiftData requires.
- **Cross-entity ownership (resolved):** aggregation lives with the
  ViewModel that owns the data being aggregated, not the ViewModel that
  consumes the result. `TransactionViewModel` computes "amount spent" (it
  queries `Transaction` directly — this is data locality, not a role
  label). `CategoryViewModel` does NOT depend on or inject
  `TransactionViewModel`. Instead, `CategoryViewModel` exposes a pure
  function, `budgetStatus(limit:spent:) -> BudgetStatus`, that takes the
  spent amount as a parameter. The View is responsible for calling both
  ViewModels and passing `TransactionViewModel`'s result into
  `CategoryViewModel`'s pure function. No ViewModel may hold a reference
  to another ViewModel. Apply this same pattern to any other logic that
  spans more than one entity.

## File Structure & Naming

- Models/Transaction.swift, Models/Category.swift — @Model types only
- Domain/ — plain value types that aren't @Model or a ViewModel. Once more
  than 2-3 files accumulate, group into subfolders by purpose, not left
  flat:
  - Domain/Errors/ — typed error enums (e.g. CategoryValidationError)
  - Domain/Formatting/ — formatters/utilities (e.g. RupiahFormatter)
  - Domain/<Feature>/ — feature-specific helper types used by more than
    one file (e.g. Domain/Transaction/ for TransactionDayGroup)
  - Shared cross-feature value types (e.g. BudgetStatus, MonthKey) stay
    at Domain/ root
- ViewModels/TransactionViewModel.swift, ViewModels/CategoryViewModel.swift
- Views/ — split by role, not left flat:
  - Views/Screens/ — full screens, named <Screen>View.swift
  - Views/Components/ — reusable pieces used across more than one screen
    (e.g. BudgetBar, TransactionRow, empty-state views, tab bar pieces)

## Do Not

- Do not put networking, persistence, or business logic inside a View
- Do not swallow errors silently — no bare try? on save/delete without
  at least logging
- Do not modify .xcodeproj/.pbxproj structure directly

## Git Conventions

**Commit messages** — Conventional Commits format, no exceptions:
`<type>: <description>` (or `<type>(<scope>): <description>` if a scope
adds clarity). `type` MUST be one of: `feat`, `fix`, `refactor`, `test`,
`chore`, `docs`. Description is imperative mood, lowercase, no period,
under ~72 characters. A body is optional — if included, use short
paragraphs or bullets, not an essay.

**Branch names** — `<type>/<issue-number>-<kebab-case-description>`,
using the same `type` as the commit (e.g. `feat/7-transaction-crud`,
`fix/9-zero-limit-validation`, `chore/21-reorganize-folders`). Always
include the issue number. Do not vary this pattern.

**PR descriptions** — keep it short and conventional, like a typical
open-source PR, not an engineering design doc:
- **Summary**: 1-3 sentences, what changed and why (not how).
- **Changes**: a short bullet list of what was touched.
- **Testing**: what to verify manually, 1-3 bullets.
- Closes #N footer.

Deep technical rationale (architecture trade-offs, alternatives
considered, edge-case reasoning) belongs in code comments or the issue
thread, not the PR description. If the PR body is longer than roughly
150 words excluding the bullet lists, it's too long — trim it.

## Design Reference

`Design/` (repo root, not part of the app target) contains the Claude
Design mockup — `SpendWise.dc.html`, `ios-frame.jsx`, `support.js`. For
any issue that builds or modifies a screen, read these files before
writing UI code. Issue bodies describe structure and behavior, not visual
details (colors, spacing, copy text, layout proportions) — those live
only in the mockup. Match them, not just the written requirements.

## Verification

A clean build is not enough — it does not catch runtime issues like broken
string formatting, incorrect chart data, or wrong budget calculations. After
building successfully, also describe what changed from a user's perspective
(what should visually appear/behave differently) so it can be checked
against the running app.

**Do not launch or boot the Simulator to visually inspect the app
yourself** (e.g. `xcrun simctl launch`, opening Simulator.app, or running
the app to "look" at it) — repeated Simulator launches are resource-heavy
and this is the user's job, not yours. Simulator boot is acceptable only
as an unavoidable side effect of running the automated test suite
(`xcodebuild test`) — never as a standalone action to check appearance.

## Build

xcodebuild -project SpendWise.xcodeproj -scheme SpendWise -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO build
