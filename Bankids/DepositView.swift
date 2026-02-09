//
//  DepositView.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import SwiftUI
import SwiftData

struct DepositView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var memo = ""

    var body: some View {
        Form {
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
                TextField("お年玉、お小遣いなど", text: $memo)
            }

            Section {
                Button {
                    deposit()
                } label: {
                    HStack {
                        Spacer()
                        Label("入金する", systemImage: "arrow.down.circle.fill")
                            .font(.headline)
                        Spacer()
                    }
                }
                .disabled(amount <= 0)
            }
        }
        .navigationTitle("入金")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var amount: Int {
        Int(amountText) ?? 0
    }

    private func deposit() {
        let transaction = Transaction(
            type: .deposit,
            amount: amount,
            memo: memo
        )
        modelContext.insert(transaction)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        DepositView()
            .modelContainer(for: Transaction.self, inMemory: true)
    }
}
