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

    let account: Account

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
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("入金")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                }
                .toolbarBackground(Color("PrimaryBlue"), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
    
                .navigationBarTitleDisplayMode(.inline)
            }
        
            private var amount: Int {
        Int(amountText) ?? 0
    }

    private func deposit() {
        let transaction = Transaction(
            type: .deposit,
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
        DepositView(account: account)
            .modelContainer(container)
    }
}
