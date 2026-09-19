import Foundation
import SwiftData
import Testing
@testable import Bankids

@MainActor
struct BackupTests {
    @Test func testRoundTripPreservesAllFieldsAndBalances() throws {
        try withStore { context, manager in
            let original = sampleArchive()
            let decoded = try BackupArchive.decode(original.encoded())
            #expect(decoded == original)
            try BackupService.restore(decoded, in: context, accountManager: manager)
            let exported = try BackupService.makeArchive(in: context, accountManager: manager)
            #expect(exported.accounts == original.accounts)
            #expect(exported.selectedAccountID == original.selectedAccountID)
            #expect(exported.selectedWalletID == original.selectedWalletID)
            #expect(exported.accounts[0].balance == 9_500)
            #expect(exported.accounts[0].wallets.map(\.balance) == [8_500, 1_000])
            #expect(exported.accounts[1].balance == 3_000)
            #expect(exported.walletCount == 3)
            #expect(exported.transactionCount == 5)
        }
    }

    @Test func testRepeatedRestoreReplacesInsteadOfDuplicating() throws {
        try withStore { context, manager in
            let archive = sampleArchive()
            try BackupService.restore(archive, in: context, accountManager: manager)
            let firstRevision = manager.dataRevision
            context.insert(Account(name: "置き換える子供"))
            // Include unrelated orphan records to prove full replacement removes them too.
            context.insert(Wallet(name: "古い口座"))
            context.insert(Transaction(type: .deposit, amount: 1, memo: "古い取引"))
            try context.save()
            try BackupService.restore(archive, in: context, accountManager: manager)
            #expect(try context.fetchCount(FetchDescriptor<Account>()) == 2)
            #expect(try context.fetchCount(FetchDescriptor<Wallet>()) == 3)
            #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 5)
            #expect(manager.dataRevision != firstRevision)
            #expect(try BackupService.makeArchive(in: context, accountManager: manager).accounts == archive.accounts)
        }
    }

    @Test func testFailedSaveRollsBackAndPreservesUnsavedEditsAndSelection() throws {
        try withStore { context, manager in
            let original = sampleArchive()
            try BackupService.restore(original, in: context, accountManager: manager)
            let account = try #require(context.fetch(FetchDescriptor<Account>()).first)
            account.name = "保存前の編集も保持"
            let revision = manager.dataRevision
            context.autosaveEnabled = true
            struct SaveFailure: Error {}
            #expect(throws: SaveFailure.self) {
                try BackupService.restore(sampleArchive(), in: context, accountManager: manager) { _ in
                    throw SaveFailure()
                }
            }
            #expect(context.autosaveEnabled)
            #expect(!context.hasChanges)
            #expect(manager.dataRevision == revision)
            #expect(manager.selectedAccountID == original.selectedAccountID)
            #expect(manager.selectedWalletID == original.selectedWalletID)
            let restored = try BackupService.makeArchive(in: context, accountManager: manager)
            #expect(restored.accounts.contains { $0.name == "保存前の編集も保持" })
            #expect(restored.transactionCount == 5)
            #expect(restored.accounts.map(\.balance) == [9_500, 3_000])
            // A separate context must still see the pre-restore records on the store.
            let reader = ModelContext(context.container)
            #expect(try reader.fetchCount(FetchDescriptor<Transaction>()) == 5)
            #expect(try reader.fetch(FetchDescriptor<Account>()).contains { $0.name == "保存前の編集も保持" })
        }
    }

    @Test(arguments: [
        "duplicateAccount", "duplicateWallet", "duplicateTransaction", "missingPair", "mismatchedAmount",
        "sameWallet", "crossAccount", "zeroAmount", "negativeAmount", "overflow", "badDate",
        "badSelection", "noWallets", "ordinaryTransactionPair", "invalidFormat", "futureVersion"
    ])
    func testInvalidArchiveLeavesExistingDataUntouched(_ mutation: String) throws {
        try withStore { context, manager in
            let original = sampleArchive()
            try BackupService.restore(original, in: context, accountManager: manager)
            let revision = manager.dataRevision
            var invalid = sampleArchive()
            switch mutation {
            case "duplicateAccount": invalid.accounts.append(invalid.accounts[0])
            case "duplicateWallet": invalid.accounts[1].wallets[0].id = invalid.accounts[0].wallets[0].id
            case "duplicateTransaction":
                invalid.accounts[1].wallets[0].transactions[0].id = invalid.accounts[0].wallets[0].transactions[0].id
            case "missingPair": invalid.accounts[0].wallets[1].transactions = []
            case "mismatchedAmount": invalid.accounts[0].wallets[1].transactions[0].amount += 1
            case "sameWallet":
                invalid.accounts[0].wallets[0].transactions.append(invalid.accounts[0].wallets[1].transactions.removeFirst())
            case "crossAccount":
                invalid.accounts[1].wallets[0].transactions.append(invalid.accounts[0].wallets[1].transactions.removeFirst())
            case "zeroAmount": invalid.accounts[0].wallets[0].transactions[0].amount = 0
            case "negativeAmount": invalid.accounts[0].wallets[0].transactions[0].amount = Int.min
            case "overflow": invalid.accounts[0].wallets[0].transactions[2].amount = Int.max
            case "badDate": invalid.accounts[0].createdAt = Date(timeIntervalSince1970: .infinity)
            case "badSelection": invalid.selectedWalletID = invalid.accounts[1].wallets[0].id
            case "noWallets": invalid.accounts[0].wallets = []
            case "ordinaryTransactionPair": invalid.accounts[1].wallets[0].transactions[0].transferPairID = UUID()
            case "invalidFormat": invalid.format = "another-app"
            default: invalid.version = 999
            }
            #expect(throws: BackupError.self) {
                try BackupService.restore(invalid, in: context, accountManager: manager)
            }
            #expect(manager.dataRevision == revision)
            #expect(manager.selectedWalletID == original.selectedWalletID)
            #expect(try BackupService.makeArchive(in: context, accountManager: manager).accounts == original.accounts)
        }
    }

    @Test func testEmptyBackupAndMissingSelection() throws {
        try withStore { context, manager in
            var archive = sampleArchive()
            archive.selectedAccountID = nil
            archive.selectedWalletID = nil
            try BackupService.restore(archive, in: context, accountManager: manager)
            #expect(manager.selectedAccountID == archive.accounts[0].id)
            #expect(manager.selectedWalletID == archive.accounts[0].wallets[0].id)
            let empty = BackupArchive(exportedAt: .now, accounts: [])
            try BackupService.restore(empty, in: context, accountManager: manager)
            #expect(try context.fetchCount(FetchDescriptor<Account>()) == 0)
            #expect(try context.fetchCount(FetchDescriptor<Wallet>()) == 0)
            #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 0)
            #expect(manager.selectedAccountID == nil)
            #expect(manager.selectedWalletID == nil)
        }
    }

    @Test func testRejectsTruncatedUnknownAndOversizedFiles() throws {
        let data = try sampleArchive().encoded()
        #expect(throws: BackupError.self) { try BackupArchive.decode(Data(data.dropLast())) }
        #expect(throws: BackupError.self) { try BackupArchive.decode(Data("{}".utf8)) }
        #expect(throws: BackupError.self) {
            try BackupArchive.decode(Data(repeating: 0, count: BackupArchive.maximumFileSize + 1))
        }
        let future = Data("{\"format\":\"jp.hibiki.bankids.backup\",\"version\":999}".utf8)
        do {
            _ = try BackupArchive.decode(future)
            Issue.record("Unsupported versions must fail before decoding the payload")
        } catch BackupError.unsupportedVersion {
            // Expected, even though the future schema omits today's required fields.
        }
    }

    @Test func testExportRejectsOrphanedRecords() throws {
        try withStore { context, manager in
            try BackupService.restore(sampleArchive(), in: context, accountManager: manager)
            context.insert(Transaction(type: .deposit, amount: 100, memo: "関連付けのない取引"))
            #expect(throws: BackupError.self) {
                try BackupService.makeArchive(in: context, accountManager: manager)
            }
        }
    }

    @Test func testFileReadAndPersistenceAcrossContainers() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let archive = sampleArchive()
        let file = directory.appendingPathComponent("FamiBank-backup.json")
        try archive.encoded().write(to: file)
        let decoded = try BackupDocument.readArchive(from: file)
        #expect(decoded == archive)

        let configuration = ModelConfiguration(url: directory.appendingPathComponent("test.store"), cloudKitDatabase: .none)
        let defaultsName = "BankidsTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        let manager = AccountManager(defaults: defaults)
        do {
            let container = try ModelContainer(for: Account.self, Wallet.self, Transaction.self, configurations: configuration)
            try BackupService.restore(decoded, in: container.mainContext, accountManager: manager)
        }
        let reopened = try ModelContainer(for: Account.self, Wallet.self, Transaction.self, configurations: configuration)
        let reloadedManager = AccountManager(defaults: defaults)
        let result = try BackupService.makeArchive(in: reopened.mainContext, accountManager: reloadedManager)
        #expect(result.accounts == archive.accounts)
        #expect(result.selectedAccountID == archive.selectedAccountID)
        #expect(result.selectedWalletID == archive.selectedWalletID)
    }

    private func withStore(_ body: (ModelContext, AccountManager) throws -> Void) throws {
        let container = try ModelContainer(
            for: Account.self, Wallet.self, Transaction.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let defaultsName = "BankidsTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: defaultsName))
        defer { defaults.removePersistentDomain(forName: defaultsName) }
        try body(container.mainContext, AccountManager(defaults: defaults))
    }

    private func sampleArchive() -> BackupArchive {
        let date = Date(timeIntervalSince1970: 1_780_000_000.125)
        let pairID = UUID()
        let parent = BackupArchive.WalletRecord(
            id: UUID(), name: "親口座", iconName: "building.columns", createdAt: date, isDefault: true,
            transactions: [
                .init(id: UUID(), type: .withdrawal, amount: 500, memo: "おやつ 🍩", date: date + 3, transferPairID: nil),
                .init(id: UUID(), type: .transferOut, amount: 1_000, memo: "振替元の編集済みメモ", date: date + 2, transferPairID: pairID),
                .init(id: UUID(), type: .deposit, amount: 10_000, memo: "お年玉\nありがとう", date: date + 1, transferPairID: nil),
            ]
        )
        let child = BackupArchive.WalletRecord(
            id: UUID(), name: "子供口座", iconName: "wallet.bifold", createdAt: date + 1, isDefault: false,
            transactions: [.init(id: UUID(), type: .transferIn, amount: 1_000, memo: "親口座 → 子供口座", date: date + 2, transferPairID: pairID)]
        )
        let first = BackupArchive.AccountRecord(id: UUID(), name: "太郎", iconName: "star.circle.fill", createdAt: date, wallets: [parent, child])
        let second = BackupArchive.AccountRecord(
            id: UUID(), name: "花子", iconName: "heart.circle.fill", createdAt: date + 1,
            wallets: [.init(
                id: UUID(), name: "親口座", iconName: "building.columns", createdAt: date, isDefault: true,
                transactions: [.init(id: UUID(), type: .deposit, amount: 3_000, memo: "お祝い", date: date, transferPairID: nil)]
            )]
        )
        return BackupArchive(exportedAt: date + 10, selectedAccountID: first.id, selectedWalletID: child.id, accounts: [first, second])
    }
}
