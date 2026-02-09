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
        .navigationTitle("出金")
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
            memo: memo
        )
        modelContext.insert(transaction)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        WithdrawView(balance: 10000)
            .modelContainer(for: Transaction.self, inMemory: true)
    }
}
