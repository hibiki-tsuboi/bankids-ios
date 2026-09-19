import Foundation
import SwiftData

@MainActor
enum BackupService {
    static func makeArchive(in context: ModelContext, accountManager: AccountManager) throws -> BackupArchive {
        try context.save()
        let accounts = try context.fetch(FetchDescriptor<Account>(sortBy: [SortDescriptor(\Account.createdAt)]))
        let records = accounts.map { account in
            BackupArchive.AccountRecord(
                id: account.id, name: account.name, iconName: account.iconName, createdAt: account.createdAt,
                wallets: account.sortedWallets.map { wallet in
                    BackupArchive.WalletRecord(
                        id: wallet.id, name: wallet.name, iconName: wallet.iconName,
                        createdAt: wallet.createdAt, isDefault: wallet.isDefault,
                        transactions: wallet.sortedTransactions.map { transaction in
                            BackupArchive.TransactionRecord(
                                id: transaction.id, type: transaction.type, amount: transaction.amount,
                                memo: transaction.memo, date: transaction.date, transferPairID: transaction.transferPairID
                            )
                        }
                    )
                }
            )
        }
        let selectedAccount = records.first { $0.id == accountManager.selectedAccountID } ?? records.first
        let selectedWallet = selectedAccount?.wallets.first { $0.id == accountManager.selectedWalletID }
            ?? selectedAccount?.wallets.first
        let archive = BackupArchive(
            exportedAt: .now, selectedAccountID: selectedAccount?.id,
            selectedWalletID: selectedWallet?.id, accounts: records
        )
        guard archive.walletCount == (try context.fetchCount(FetchDescriptor<Wallet>())),
              archive.transactionCount == (try context.fetchCount(FetchDescriptor<Transaction>()))
        else { throw BackupError.incompleteData }
        try archive.validate()
        return archive
    }

    static func restore(
        _ archive: BackupArchive,
        in context: ModelContext,
        accountManager: AccountManager,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        // Validate everything before touching the current data or selection.
        try archive.validate()
        // Preserve unsaved edits as the rollback baseline.
        try context.save()
        let oldTransactions = try context.fetch(FetchDescriptor<Transaction>())
        let oldWallets = try context.fetch(FetchDescriptor<Wallet>())
        let oldAccounts = try context.fetch(FetchDescriptor<Account>())
        let wasAutosaveEnabled = context.autosaveEnabled
        context.autosaveEnabled = false
        defer { context.autosaveEnabled = wasAutosaveEnabled }

        do {
            // Use pending object deletions, never a batch delete that bypasses rollback.
            for transaction in oldTransactions { context.delete(transaction) }
            for wallet in oldWallets { context.delete(wallet) }
            for account in oldAccounts { context.delete(account) }

            for record in archive.accounts {
                let account = Account(name: record.name, iconName: record.iconName)
                account.id = record.id
                account.createdAt = record.createdAt
                context.insert(account)
                for walletRecord in record.wallets {
                    let wallet = Wallet(
                        name: walletRecord.name, iconName: walletRecord.iconName,
                        isDefault: walletRecord.isDefault, account: account
                    )
                    wallet.id = walletRecord.id
                    wallet.createdAt = walletRecord.createdAt
                    context.insert(wallet)
                    for transactionRecord in walletRecord.transactions {
                        let transaction = Transaction(
                            type: transactionRecord.type, amount: transactionRecord.amount,
                            memo: transactionRecord.memo, date: transactionRecord.date,
                            wallet: wallet, transferPairID: transactionRecord.transferPairID
                        )
                        transaction.id = transactionRecord.id
                        context.insert(transaction)
                    }
                }
            }
            // One save commits the entire replacement. A failure restores the previous graph.
            try save(context)
        } catch {
            context.rollback()
            throw error
        }

        let selectedAccount = archive.accounts.first { $0.id == archive.selectedAccountID } ?? archive.accounts.first
        accountManager.selectedAccountID = selectedAccount?.id
        accountManager.selectedWalletID = selectedAccount?.wallets.first { $0.id == archive.selectedWalletID }?.id
            ?? selectedAccount?.wallets.first?.id
        accountManager.dataRevision = UUID()
    }
}
