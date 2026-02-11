//
//  TransferView.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/11.
//

import SwiftUI
import SwiftData

struct TransferView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account

    @State private var fromWalletID: UUID?
    @State private var toWalletID: UUID?
    @State private var amountText = ""
    @State private var memo = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    private var wallets: [Wallet] {
        account.sortedWallets
    }

    private var fromWallet: Wallet? {
        wallets.first { $0.id == fromWalletID }
    }

    private var toWallet: Wallet? {
        wallets.first { $0.id == toWalletID }
    }

    private var amount: Int {
        Int(amountText) ?? 0
    }

    private var canTransfer: Bool {
        fromWalletID != nil && toWalletID != nil && fromWalletID != toWalletID && amount > 0
    }

    var body: some View {
        Form {
            Section("振替元") {
                Picker("振替元口座", selection: $fromWalletID) {
                    Text("選択してください").tag(nil as UUID?)
                    ForEach(wallets) { wallet in
                        HStack {
                            Image(systemName: wallet.iconName)
                            Text("\(wallet.name)（¥\(wallet.balance.formatted())）")
                        }
                        .tag(wallet.id as UUID?)
                    }
                }
            }

            Section("振替先") {
                Picker("振替先口座", selection: $toWalletID) {
                    Text("選択してください").tag(nil as UUID?)
                    ForEach(wallets) { wallet in
                        HStack {
                            Image(systemName: wallet.iconName)
                            Text("\(wallet.name)（¥\(wallet.balance.formatted())）")
                        }
                        .tag(wallet.id as UUID?)
                    }
                }
            }

            Section("金額") {
                HStack {
                    Text("¥")
                        .font(.title2.bold())
                    TextField("0", text: $amountText)
                        .keyboardType(.numberPad)
                        .font(.title2.monospacedDigit())
                }
            }

            Section("メモ") {
                TextField("振替メモ", text: $memo)
            }

            Section {
                Button {
                    transfer()
                } label: {
                    HStack {
                        Spacer()
                        Label("振替する", systemImage: "arrow.left.arrow.right.circle.fill")
                            .font(.headline)
                        Spacer()
                    }
                }
                .disabled(!canTransfer)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("口座振替")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(Color("PrimaryBlue"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if wallets.count >= 2 {
                fromWalletID = wallets[0].id
                toWalletID = wallets[1].id
            }
        }
        .alert("エラー", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func transfer() {
        guard let from = fromWallet, let to = toWallet else { return }
        guard from.id != to.id else {
            errorMessage = "振替元と振替先が同じです。"
            showingError = true
            return
        }
        guard amount > 0 else { return }
        guard amount <= from.balance else {
            errorMessage = "残高が足りません。\(from.name)の残高は ¥\(from.balance.formatted()) です。"
            showingError = true
            return
        }

        let pairID = UUID()
        let memoText = memo.isEmpty ? "\(from.name) → \(to.name)" : memo

        let outTransaction = Transaction(
            type: .transferOut,
            amount: amount,
            memo: memoText,
            wallet: from,
            transferPairID: pairID
        )
        let inTransaction = Transaction(
            type: .transferIn,
            amount: amount,
            memo: memoText,
            wallet: to,
            transferPairID: pairID
        )

        modelContext.insert(outTransaction)
        modelContext.insert(inTransaction)
        dismiss()
    }
}

#Preview {
    let container = try! ModelContainer(for: Account.self, Wallet.self, Transaction.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let account = Account(name: "テスト")
    container.mainContext.insert(account)
    let wallet1 = Wallet(name: "親口座", iconName: "building.columns", isDefault: true, account: account)
    let wallet2 = Wallet(name: "財布口座", iconName: "wallet.bifold", isDefault: false, account: account)
    container.mainContext.insert(wallet1)
    container.mainContext.insert(wallet2)
    return NavigationStack {
        TransferView(account: account)
            .modelContainer(container)
    }
}
