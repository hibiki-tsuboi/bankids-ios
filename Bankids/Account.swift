//
//  Account.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID
    var name: String
    var iconName: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Wallet.account)
    var wallets: [Wallet] = []

    init(name: String, iconName: String = "person.circle.fill") {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.createdAt = .now
    }

    var balance: Int {
        wallets.reduce(0) { $0 + $1.balance }
    }

    var sortedTransactions: [Transaction] {
        wallets.flatMap(\.transactions).sorted { $0.date > $1.date }
    }

    var sortedWallets: [Wallet] {
        wallets.sorted { $0.createdAt < $1.createdAt }
    }
}
