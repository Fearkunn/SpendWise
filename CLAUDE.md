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
- Domain/ — plain value types that aren't @Model or a ViewModel (e.g.
  BudgetStatus). Use this for pure business-logic types shared across
  ViewModels, not Models/.
- ViewModels/TransactionViewModel.swift, ViewModels/CategoryViewModel.swift
- Views/ — one file per screen, named <Screen>View.swift

## Do Not

- Do not put networking, persistence, or business logic inside a View
- Do not swallow errors silently — no bare try? on save/delete without
  at least logging
- Do not modify .xcodeproj/.pbxproj structure directly

## Verification

A clean build is not enough — it does not catch runtime issues like broken
string formatting, incorrect chart data, or wrong budget calculations. After
building successfully, also describe what changed from a user's perspective
(what should visually appear/behave differently) so it can be checked
against the running app.

## Build

xcodebuild -project SpendWise.xcodeproj -scheme SpendWise -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO build
