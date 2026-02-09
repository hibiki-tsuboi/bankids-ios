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

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction] = []

    init(name: String, iconName: String = "person.circle.fill") {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.createdAt = .now
    }

    var balance: Int {
        transactions.reduce(0) { result, transaction in
            switch transaction.type {
            case .deposit:
                return result + transaction.amount
            case .withdrawal:
                return result - transaction.amount
            }
        }
    }

    var sortedTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }
    }
}
