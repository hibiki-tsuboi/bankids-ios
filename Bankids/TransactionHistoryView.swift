//
//  TransactionHistoryView.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    var body: some View {
        List {
            if transactions.isEmpty {
                ContentUnavailableView(
                    "取引履歴がありません",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("入金または出金を行うと、ここに表示されます。")
                )
            } else {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .navigationTitle("取引明細")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TransactionHistoryView()
            .modelContainer(for: Transaction.self, inMemory: true)
    }
}
