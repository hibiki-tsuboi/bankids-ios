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
    case transferIn
    case transferOut
}

@Model
final class Transaction {
    var id: UUID
    var type: TransactionType
    var amount: Int
    var memo: String
    var date: Date
    var wallet: Wallet?
    var transferPairID: UUID?

    init(type: TransactionType, amount: Int, memo: String, date: Date = .now, wallet: Wallet? = nil, transferPairID: UUID? = nil) {
        self.id = UUID()
        self.type = type
        self.amount = amount
        self.memo = memo
        self.date = date
        self.wallet = wallet
        self.transferPairID = transferPairID
    }
}
