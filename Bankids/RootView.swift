//
//  RootView.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AccountManager.self) private var accountManager
    @Query private var accounts: [Account]

    var body: some View {
        Group {
            if accounts.isEmpty {
                AccountSetupView()
            } else {
                ContentView()
            }
        }
        .onChange(of: accounts.count) {
            if !accounts.isEmpty && accountManager.selectedAccountID == nil {
                accountManager.selectedAccountID = accounts.first?.id
            }
        }
        .onAppear {
            if !accounts.isEmpty && accountManager.selectedAccountID == nil {
                accountManager.selectedAccountID = accounts.first?.id
            }
            autoSelectWallet()
        }
        .onChange(of: accountManager.selectedAccountID) {
            autoSelectWallet()
        }
    }

    private func autoSelectWallet() {
        guard let account = accounts.first(where: { $0.id == accountManager.selectedAccountID }) else { return }
        let wallets = account.sortedWallets
        if accountManager.selectedWalletID == nil || !wallets.contains(where: { $0.id == accountManager.selectedWalletID }) {
            accountManager.selectedWalletID = wallets.first?.id
        }
    }
}

struct AccountSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AccountManager.self) private var accountManager

    @State private var name = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color("PrimaryGreen"), Color("PrimaryBlue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 10)

                    Image(systemName: "banknote.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text("Bankidsへようこそ")
                        .font(.title.bold())
                    Text("お子さまの名前を入力してください")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                TextField("名前", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 40)

                Button {
                    createAccount()
                } label: {
                    Text("はじめる")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("PrimaryBlue"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color("PrimaryBlue").opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)

                Spacer()
                Spacer()
            }
            .navigationTitle("")
        }
    }

    private func createAccount() {
        let account = Account(name: name.trimmingCharacters(in: .whitespaces))
        modelContext.insert(account)

        let wallet1 = Wallet(name: "親口座", iconName: "building.columns", isDefault: true, account: account)
        let wallet2 = Wallet(name: "財布口座", iconName: "wallet.bifold", isDefault: false, account: account)
        modelContext.insert(wallet1)
        modelContext.insert(wallet2)

        accountManager.selectedAccountID = account.id
        accountManager.selectedWalletID = wallet1.id
    }
}
