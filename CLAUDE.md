# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bankids is an iOS app (bundle ID: `jp.hibiki.Bankids`) built with **SwiftUI** and **SwiftData**. Created with Xcode 26.2, targeting iOS 26.2+, Swift 5.0.

## Build Commands

```bash
# Build the project
xcodebuild -project Bankids.xcodeproj -scheme Bankids -sdk iphonesimulator build

# Build for a specific simulator
xcodebuild -project Bankids.xcodeproj -scheme Bankids -destination 'platform=iOS Simulator,name=iPhone 16' build
```

No tests are configured yet. No external dependencies (no SPM packages, CocoaPods, or Carthage).

## Architecture

- **Pure SwiftUI** app using the `@main` App protocol (`BankidsApp.swift`)
- **SwiftData** for persistence — `ModelContainer` is configured at the app level and injected via `.modelContainer()` modifier
- Models use the `@Model` macro (see `Item.swift`)
- Views use `@Query` for data fetching and `@Environment(\.modelContext)` for mutations

## Swift Concurrency Settings

The project enables modern Swift concurrency defaults:
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (all types are MainActor-isolated by default)
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`

## Language rules
- Always answer in Japanese.
