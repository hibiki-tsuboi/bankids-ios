//
//  BankidsApp.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import SwiftUI
import SwiftData

@main
struct FamiBankApp: App {
    @State private var accountManager: AccountManager

    let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([
            Account.self,
            Wallet.self,
            Transaction.self,
        ])
        var modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        var defaults = UserDefaults.standard

        do {
            #if DEBUG
            // Each UI test gets a separate persistent store and preferences, including across relaunches.
            if let value = ProcessInfo.processInfo.environment["BANKIDS_UI_TEST_ID"],
               let testID = UUID(uuidString: value) {
                let directory = FileManager.default.temporaryDirectory
                    .appendingPathComponent("BankidsUITests/\(testID.uuidString)", isDirectory: true)
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                modelConfiguration = ModelConfiguration(
                    schema: schema, url: directory.appendingPathComponent("test.store"), cloudKitDatabase: .none
                )
                defaults = UserDefaults(suiteName: "jp.hibiki.bankids.uitests.\(testID.uuidString)")!
            }
            #endif
            sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            _accountManager = State(initialValue: AccountManager(defaults: defaults))
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(accountManager)
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
