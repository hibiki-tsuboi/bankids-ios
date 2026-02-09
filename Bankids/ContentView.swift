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
    @Environment(AccountManager.self) private var accountManager
    @Query private var accounts: [Account]

    @State private var showingDeposit = false
    @State private var showingWithdraw = false
    @State private var showingAccountList = false

    private var selectedAccount: Account? {
        accounts.first { $0.id == accountManager.selectedAccountID }
    }

    private var balance: Int {
        selectedAccount?.balance ?? 0
    }

    private var recentTransactions: [Transaction] {
        Array((selectedAccount?.sortedTransactions ?? []).prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    balanceCard
                    actionButtons
                    recentTransactionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(selectedAccount?.name ?? "Bankids")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingAccountList = true
                    } label: {
                        Image(systemName: selectedAccount?.iconName ?? "person.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .navigationDestination(isPresented: $showingDeposit) {
                if let account = selectedAccount {
                    DepositView(account: account)
                }
            }
            .navigationDestination(isPresented: $showingWithdraw) {
                if let account = selectedAccount {
                    WithdrawView(account: account, balance: balance)
                }
            }
            .sheet(isPresented: $showingAccountList) {
                AccountListView()
            }
        }
    }

    // MARK: - 残高カード

    private var balanceCard: some View {
        VStack(spacing: 8) {
            Text("残高")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Text("¥\(balance.formatted())")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color("PrimaryBlue"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
                    .background(Color("PrimaryGreen"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            Button {
                showingWithdraw = true
            } label: {
                Label("出金", systemImage: "arrow.up.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AccentRed"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
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
                if let account = selectedAccount {
                    NavigationLink {
                        TransactionHistoryView(account: account)
                    } label: {
                        Text("すべての明細を見る")
                            .font(.subheadline)
                    }
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
                .foregroundStyle(transaction.type == .deposit ? Color("PrimaryGreen") : Color("AccentRed"))
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
                .foregroundStyle(transaction.type == .deposit ? Color("PrimaryGreen") : Color("AccentRed"))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Account.self, Transaction.self], inMemory: true)
        .environment(AccountManager())
}
