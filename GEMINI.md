# Project: Bankids iOS App

## Project Overview

This is an iOS application named "Bankids", developed using SwiftUI and SwiftData. It appears to be a personal finance or banking application, featuring account management, transaction tracking (deposits, withdrawals, history), and utilizes SwiftData for persistence.

- **Primary Technologies:** Swift, SwiftUI, SwiftData
- **Platform:** iOS
- **Project Type:** Xcode project

## Building and Running

This project is an Xcode project and can be opened, built, and run using Xcode.

To build the project from the command line, navigate to the project root directory and use `xcodebuild`:

```bash
xcodebuild build -scheme Bankids -destination 'platform=iOS Simulator,name=iPhone 15'
```

To run tests (if any exist, which are not currently identified in this analysis):

```bash
xcodebuild test -scheme Bankids -destination 'platform=iOS Simulator,name=iPhone 15'
```

Replace `iPhone 15` with the desired simulator name if needed.

## Development Conventions

The project adheres to standard Swift and iOS development conventions, utilizing SwiftUI for the user interface and SwiftData for data persistence.

- **Naming Conventions:** Standard Swift naming conventions are followed (e.g., `CamelCase` for types, `camelCase` for properties and methods).
- **Architecture:** The application structure suggests a modular approach typical for SwiftUI applications, with distinct views (`ContentView`, `AccountListView`, `DepositView`, etc.) and data models (`Account`, `Transaction`).
- **Assets:** Image assets are managed within `Assets.xcassets`.

## Language rules
- Always answer in Japanese.
