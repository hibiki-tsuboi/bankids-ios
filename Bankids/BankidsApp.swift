//
//  BankidsApp.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import SwiftUI
import SwiftData

@main
struct BankidsApp: App {
    @State private var accountManager = AccountManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            Wallet.self,
            Transaction.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(accountManager)
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
