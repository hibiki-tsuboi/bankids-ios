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

                Image(systemName: "banknote.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color("PrimaryGreen"))

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
        accountManager.selectedAccountID = account.id
    }
}
