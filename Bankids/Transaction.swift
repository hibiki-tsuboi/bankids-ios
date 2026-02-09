//
//  Transaction.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import Foundation
import SwiftData

enum TransactionType: String, Codable {
    case deposit
    case withdrawal
}

@Model
final class Transaction {
    var id: UUID
    var type: TransactionType
    var amount: Int
    var memo: String
    var date: Date
    var account: Account?

    init(type: TransactionType, amount: Int, memo: String, date: Date = .now, account: Account? = nil) {
        self.id = UUID()
        self.type = type
        self.amount = amount
        self.memo = memo
        self.date = date
        self.account = account
    }
}
