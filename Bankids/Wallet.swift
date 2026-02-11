//
//  Wallet.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/11.
//

import Foundation
import SwiftData

@Model
final class Wallet {
    var id: UUID
    var name: String
    var iconName: String
    var createdAt: Date
    var isDefault: Bool

    @Relationship(deleteRule: .cascade, inverse: \Transaction.wallet)
    var transactions: [Transaction] = []

    var account: Account?

    init(name: String, iconName: String = "banknote", isDefault: Bool = false, account: Account? = nil) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.createdAt = .now
        self.isDefault = isDefault
        self.account = account
    }

    var balance: Int {
        transactions.reduce(0) { result, transaction in
            switch transaction.type {
            case .deposit, .transferIn:
                return result + transaction.amount
            case .withdrawal, .transferOut:
                return result - transaction.amount
            }
        }
    }

    var sortedTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }
    }
}
