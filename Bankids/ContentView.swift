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
    @State private var showingTransfer = false
    @State private var showingAccountList = false

    private var selectedAccount: Account? {
        accounts.first { $0.id == accountManager.selectedAccountID }
    }

    private var selectedWallet: Wallet? {
        guard let account = selectedAccount else { return nil }
        if let walletID = accountManager.selectedWalletID,
           let wallet = account.sortedWallets.first(where: { $0.id == walletID }) {
            return wallet
        }
        return account.sortedWallets.first
    }

    private var balance: Int {
        selectedWallet?.balance ?? 0
    }

    private var recentTransactions: [Transaction] {
        Array((selectedWallet?.sortedTransactions ?? []).prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    walletPicker
                    balanceCard
                    actionButtons
                    recentTransactionsSection
                }
                .padding()
            }
            .background(Color("LightGray"))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(selectedAccount?.name ?? "Bankids")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingAccountList = true
                    } label: {
                        Image(systemName: selectedAccount?.iconName ?? "person.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
            }
            .navigationDestination(isPresented: $showingDeposit) {
                if let wallet = selectedWallet {
                    DepositView(wallet: wallet)
                }
            }
            .navigationDestination(isPresented: $showingWithdraw) {
                if let wallet = selectedWallet {
                    WithdrawView(wallet: wallet, balance: balance)
                }
            }
            .navigationDestination(isPresented: $showingTransfer) {
                if let account = selectedAccount {
                    TransferView(account: account)
                }
            }
            .sheet(isPresented: $showingAccountList) {
                AccountListView()
            }
            .toolbarBackground(Color("PrimaryBlue"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - ウォレットピッカー

    private var walletPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if let account = selectedAccount {
                    ForEach(account.sortedWallets) { wallet in
                        Button {
                            accountManager.selectedWalletID = wallet.id
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: wallet.iconName)
                                    .font(.caption)
                                Text(wallet.name)
                                    .font(.subheadline.bold())
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedWallet?.id == wallet.id
                                    ? Color("PrimaryBlue")
                                    : Color.white
                            )
                            .foregroundStyle(
                                selectedWallet?.id == wallet.id
                                    ? .white
                                    : Color("PrimaryBlue")
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 残高カード

    private var balanceCard: some View {
        VStack(spacing: 8) {
            Text(selectedWallet?.name ?? "残高")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Text("¥\(balance.formatted())")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color("PrimaryBlue"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }

    // MARK: - アクションボタン

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingDeposit = true
            } label: {
                Label("入金", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color("PrimaryGreen"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: Color("PrimaryGreen").opacity(0.4), radius: 8, x: 0, y: 4)
            }

            Button {
                showingWithdraw = true
            } label: {
                Label("出金", systemImage: "arrow.up.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color("AccentRed"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: Color("AccentRed").opacity(0.4), radius: 8, x: 0, y: 4)
            }

            Button {
                showingTransfer = true
            } label: {
                Label("振替", systemImage: "arrow.left.arrow.right.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color("AccentYellow"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(color: Color("AccentYellow").opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .disabled((selectedAccount?.wallets.count ?? 0) < 2)
        }
    }

    // MARK: - 最近の取引

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近の取引")
                    .font(.headline)
                Spacer()
                if let wallet = selectedWallet {
                    NavigationLink {
                        TransactionHistoryView(wallet: wallet)
                    } label: {
                        Text("すべての明細を見る")
                            .font(.subheadline)
                            .foregroundStyle(Color("PrimaryBlue"))
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
        .background(Color("LightGray"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 取引行

struct TransactionRow: View {
    let transaction: Transaction

    private var icon: String {
        switch transaction.type {
        case .deposit:
            return "arrow.down.circle.fill"
        case .withdrawal:
            return "arrow.up.circle.fill"
        case .transferIn:
            return "arrow.right.circle.fill"
        case .transferOut:
            return "arrow.left.circle.fill"
        }
    }

    private var color: Color {
        switch transaction.type {
        case .deposit, .transferIn:
            return Color("PrimaryGreen")
        case .withdrawal, .transferOut:
            return Color("AccentRed")
        }
    }

    private var label: String {
        if !transaction.memo.isEmpty { return transaction.memo }
        switch transaction.type {
        case .deposit: return "入金"
        case .withdrawal: return "出金"
        case .transferIn: return "振替入金"
        case .transferOut: return "振替出金"
        }
    }

    private var sign: String {
        switch transaction.type {
        case .deposit, .transferIn: return "+"
        case .withdrawal, .transferOut: return "-"
        }
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.body)
                Text(transaction.date.formatted(Date.FormatStyle(date: .long, time: .omitted).locale(Locale(identifier: "ja_JP"))))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(sign)¥\(transaction.amount.formatted())")
                .font(.body.monospacedDigit().bold())
                .foregroundStyle(color)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Account.self, Wallet.self, Transaction.self], inMemory: true)
        .environment(AccountManager())
}
