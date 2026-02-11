//
//  AccountListView.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import SwiftUI
import SwiftData

struct AccountListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AccountManager.self) private var accountManager
    @Query(sort: \Account.createdAt) private var accounts: [Account]

    @State private var showingAddAccount = false
    @State private var accountToDelete: Account?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("アカウント") {
                    ForEach(accounts) { account in
                        Button {
                            accountManager.selectedAccountID = account.id
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: account.iconName)
                                    .font(.title2)
                                    .foregroundStyle(Color("PrimaryBlue"))
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name)
                                        .font(.body)
                                    Text("¥\(account.balance.formatted())")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if account.id == accountManager.selectedAccountID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("PrimaryBlue"))
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .foregroundStyle(.primary)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                accountToDelete = account
                                showingDeleteConfirmation = true
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showingAddAccount = true
                    } label: {
                        Label("アカウントを追加", systemImage: "plus.circle.fill")
                    }
                    .foregroundStyle(Color("PrimaryGreen"))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .shadow(color: Color("PrimaryGreen").opacity(0.3), radius: 5, x: 0, y: 2)
                }
            }
            .listStyle(.plain)
            .background(Color("LightGray"))
            .listRowSeparator(.hidden)
            .navigationTitle("アカウント")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
            .alert("アカウントを削除", isPresented: $showingDeleteConfirmation) {
                Button("削除", role: .destructive) {
                    if let account = accountToDelete {
                        deleteAccount(account)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                if let account = accountToDelete {
                    Text("\(account.name)のアカウントとすべての取引履歴が削除されます。この操作は取り消せません。")
                }
            }
        }
    }

    private func deleteAccount(_ account: Account) {
        let wasSelected = account.id == accountManager.selectedAccountID
        modelContext.delete(account)

        if wasSelected {
            let remaining = accounts.filter { $0.id != account.id }
            accountManager.selectedAccountID = remaining.first?.id
        }
    }
}

struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AccountManager.self) private var accountManager

    @State private var name = ""

    private let iconOptions = [
        "person.circle.fill",
        "figure.child",
        "star.circle.fill",
        "heart.circle.fill",
        "leaf.circle.fill",
        "moon.circle.fill",
    ]
    @State private var selectedIcon = "person.circle.fill"

    var body: some View {
        NavigationStack {
            Form {
                Section("名前") {
                    TextField("お子さまの名前", text: $name)
                }
            }
            .navigationTitle("アカウント追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("追加") {
                        let account = Account(name: name.trimmingCharacters(in: .whitespaces), iconName: selectedIcon)
                        modelContext.insert(account)

                        let wallet1 = Wallet(name: "親口座", iconName: "building.columns", isDefault: true, account: account)
                        let wallet2 = Wallet(name: "財布口座", iconName: "wallet.bifold", isDefault: false, account: account)
                        modelContext.insert(wallet1)
                        modelContext.insert(wallet2)

                        accountManager.selectedAccountID = account.id
                        accountManager.selectedWalletID = wallet1.id
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .tint(Color("PrimaryBlue"))
        }
    }
}
