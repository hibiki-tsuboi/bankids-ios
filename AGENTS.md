# Repository Guidelines

## Project Structure & Module Organization

FamiBank is a SwiftUI/SwiftData allowance tracker for iOS 26.0+. The Xcode project, target, and scheme retain the name `Bankids`; there are no external dependencies.

- `Bankids/`: Swift sources. `BankidsApp.swift` defines `FamiBankApp`, configures persistence, and injects `AccountManager`.
- `Account.swift`, `Wallet.swift`, and `Transaction.swift`: SwiftData models; accounts contain wallets, which contain transactions.
- `*View.swift`: screens for setup, account selection, deposits, withdrawals, transfers, and history.
- `Bankids/Assets.xcassets/`: app icon and named colors. `docs/preview_*.png` contains app previews.
- `Bankids.xcodeproj/`: build settings. `README.md` and `privacy-policy.md` describe the product and privacy practices.

## Build, Test, and Development Commands

Use Xcode 26.2 or newer with an iOS simulator runtime.

```bash
# Build for the simulator without device signing
xcodebuild -project Bankids.xcodeproj -scheme Bankids \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build

# List available simulator destinations
xcodebuild -project Bankids.xcodeproj -scheme Bankids -showdestinations
```

For local execution, open `Bankids.xcodeproj` in Xcode, select the `Bankids` scheme and an iOS 26+ simulator, then press Command-R. Use existing `#Preview` blocks for focused UI work.

## Coding Style & Naming Conventions

Use four-space indentation, `UpperCamelCase` types, and `lowerCamelCase` properties and functions. Name screen types/files with the `View` suffix. Match surrounding SwiftUI modifier formatting and keep implementation helpers `private`.

Use `@Model` for persisted entities, `@Query` for fetching, and the environment model context for mutations. Preserve integer yen amounts, paired transfer IDs, and cascade relationships. Respect the project's default `MainActor` isolation. Keep interface text consistent with the existing Japanese UI and reuse named color assets. No formatter or linter is configured.

## Testing Guidelines

No automated test target, testing framework, or coverage threshold is configured; `xcodebuild test` is not currently a validation step. Build and manually verify affected flows, including balances, transfers, account/wallet switching, memo edits, and persistence after relaunch.

When adding automated tests, create a test target and use descriptive names such as `testTransferPreservesAccountBalance`. Use in-memory SwiftData containers for isolated persistence tests.

## Commit & Pull Request Guidelines

Recent commits use an emoji, category, and concise Japanese summary, for example `✨ Feat: 取引行タップでメモを編集できる機能を追加`. Follow this pattern and keep commits focused.

No PR template is present. Include the change's purpose, behavior affected, linked issues when applicable, and build/manual verification results. Attach screenshots for UI changes. Keep generated builds, signing credentials, and Xcode user state out of commits.
