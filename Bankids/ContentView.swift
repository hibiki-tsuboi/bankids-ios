//
//  ContentView.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var showingDeposit = false
    @State private var showingWithdraw = false

    private var balance: Int {
        transactions.reduce(0) { result, transaction in
            switch transaction.type {
            case .deposit:
                return result + transaction.amount
            case .withdrawal:
                return result - transaction.amount
            }
        }
    }

    private var recentTransactions: [Transaction] {
        Array(transactions.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 残高カード
                    balanceCard

                    // アクションボタン
                    actionButtons

                    // 最近の取引
                    recentTransactionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Bankids")
            .navigationDestination(isPresented: $showingDeposit) {
                DepositView()
            }
            .navigationDestination(isPresented: $showingWithdraw) {
                WithdrawView(balance: balance)
            }
        }
    }

    // MARK: - 残高カード

    private var balanceCard: some View {
        VStack(spacing: 8) {
            Text("残高")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("¥\(balance.formatted())")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - アクションボタン

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                showingDeposit = true
            } label: {
                Label("入金", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                showingWithdraw = true
            } label: {
                Label("出金", systemImage: "arrow.up.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - 最近の取引

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近の取引")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    TransactionHistoryView()
                } label: {
                    Text("すべての明細を見る")
                        .font(.subheadline)
                }
            }

            if recentTransactions.isEmpty {
                Text("取引履歴がありません")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(recentTransactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 取引行

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack {
            Image(systemName: transaction.type == .deposit ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundStyle(transaction.type == .deposit ? .green : .red)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.memo.isEmpty ? (transaction.type == .deposit ? "入金" : "出金") : transaction.memo)
                    .font(.body)
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(transaction.type == .deposit ? "+" : "-")¥\(transaction.amount.formatted())")
                .font(.body.monospacedDigit().bold())
                .foregroundStyle(transaction.type == .deposit ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
