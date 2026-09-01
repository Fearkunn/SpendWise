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
- If a piece of logic needs data from more than one entity (e.g. "how much
  has been spent against this category's budget this month"), decide
  explicitly which ViewModel owns it rather than guessing — flag the
  ambiguity if it isn't obvious from existing rules.

## File Structure & Naming

- Models/Transaction.swift, Models/Category.swift
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
