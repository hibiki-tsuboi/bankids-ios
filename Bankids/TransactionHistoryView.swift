//
//  TransactionHistoryView.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import SwiftUI
import SwiftData

struct TransactionHistoryView: View {
    let wallet: Wallet

    private var transactions: [Transaction] {
        wallet.sortedTransactions
    }

    var body: some View {
        List {
            if transactions.isEmpty {
                ContentUnavailableView(
                    "取引履歴がありません",
                    systemImage: "dollarsign.circle",
                    description: Text("入金または出金を行うと、ここに表示されます。")
                )
                .foregroundStyle(Color("AccentYellow"))
            } else {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .listStyle(.plain)
        .background(Color("LightGray"))
        .listRowSeparator(.hidden)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("取引明細")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(Color("PrimaryBlue"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let container = try! ModelContainer(for: Account.self, Wallet.self, Transaction.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let account = Account(name: "テスト")
    container.mainContext.insert(account)
    let wallet = Wallet(name: "親口座", iconName: "building.columns", isDefault: true, account: account)
    container.mainContext.insert(wallet)
    return NavigationStack {
        TransactionHistoryView(wallet: wallet)
            .modelContainer(container)
    }
}
