//
//  WithdrawView.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import SwiftUI
import SwiftData

struct WithdrawView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account
    let balance: Int

    @State private var amountText = ""
    @State private var memo = ""
    @State private var showingError = false

    var body: some View {
        Form {
            Section("現在の残高") {
                Text("¥\(balance.formatted())")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(.secondary)
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
                TextField("おもちゃ、お菓子など", text: $memo)
            }

            Section {
                Button {
                    withdraw()
                } label: {
                    HStack {
                        Spacer()
                        Label("出金する", systemImage: "arrow.up.circle.fill")
                            .font(.headline)
                        Spacer()
                    }
                }
                .disabled(amount <= 0)
            }
        }

        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("出金")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .toolbarBackground(Color("PrimaryBlue"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .alert("残高不足", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("残高が足りません。現在の残高は ¥\(balance.formatted()) です。")
        }
    }

    private var amount: Int {
        Int(amountText) ?? 0
    }

    private func withdraw() {
        guard amount <= balance else {
            showingError = true
            return
        }
        let transaction = Transaction(
            type: .withdrawal,
            amount: amount,
            memo: memo,
            account: account
        )
        modelContext.insert(transaction)
        dismiss()
    }
}

#Preview {
    let container = try! ModelContainer(for: Account.self, Transaction.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let account = Account(name: "テスト")
    container.mainContext.insert(account)
    return NavigationStack {
        WithdrawView(account: account, balance: 10000)
            .modelContainer(container)
    }
}
