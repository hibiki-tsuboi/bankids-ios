import Foundation

nonisolated struct BackupArchive: Codable, Equatable, Sendable {
    static let currentVersion = 1
    static let formatIdentifier = "jp.hibiki.bankids.backup"
    static let maximumFileSize = 20 * 1_024 * 1_024

    var format = formatIdentifier
    var version = currentVersion
    var exportedAt: Date
    var selectedAccountID: UUID?
    var selectedWalletID: UUID?
    var accounts: [AccountRecord]

    struct AccountRecord: Codable, Equatable, Sendable, Identifiable {
        var id: UUID
        var name: String
        var iconName: String
        var createdAt: Date
        var wallets: [WalletRecord]

        var balance: Int { wallets.reduce(0) { $0 + $1.balance } }
    }

    struct WalletRecord: Codable, Equatable, Sendable {
        var id: UUID
        var name: String
        var iconName: String
        var createdAt: Date
        var isDefault: Bool
        var transactions: [TransactionRecord]

        var balance: Int {
            transactions.reduce(0) { $0 + $1.signedAmount }
        }
    }

    struct TransactionRecord: Codable, Equatable, Sendable {
        var id: UUID
        var type: TransactionType
        var amount: Int
        var memo: String
        var date: Date
        var transferPairID: UUID?

        var signedAmount: Int {
            switch type {
            case .deposit, .transferIn: amount
            case .withdrawal, .transferOut: -amount
            }
        }
    }

    var walletCount: Int { accounts.reduce(0) { $0 + $1.wallets.count } }
    var transactionCount: Int {
        accounts.reduce(0) { count, account in
            count + account.wallets.reduce(0) { $0 + $1.transactions.count }
        }
    }

    func encoded() throws -> Data {
        try validate()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        guard data.count <= Self.maximumFileSize else { throw BackupError.fileTooLarge }
        return data
    }

    static func decode(_ data: Data) throws -> Self {
        guard data.count <= maximumFileSize else { throw BackupError.fileTooLarge }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        // Check the envelope first so newer formats get a useful error even if their schema changed.
        struct Header: Decodable {
            let format: String
            let version: Int
        }
        do {
            let header = try decoder.decode(Header.self, from: data)
            guard header.format == formatIdentifier else { throw BackupError.invalidFile }
            guard header.version == currentVersion else { throw BackupError.unsupportedVersion }
            let archive = try decoder.decode(Self.self, from: data)
            try archive.validate()
            return archive
        } catch let error as BackupError {
            throw error
        } catch {
            throw BackupError.invalidFile
        }
    }

    func validate() throws {
        guard format == Self.formatIdentifier else { throw BackupError.invalidFile }
        guard version == Self.currentVersion else { throw BackupError.unsupportedVersion }
        try Self.validateDate(exportedAt)
        var accountIDs = Set<UUID>()
        var walletIDs = Set<UUID>()
        var transactionIDs = Set<UUID>()
        var pairs: [UUID: [(transaction: TransactionRecord, accountID: UUID, walletID: UUID)]] = [:]

        for account in accounts {
            guard accountIDs.insert(account.id).inserted,
                  !account.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !account.wallets.isEmpty else { throw BackupError.invalidData }
            try Self.validateDate(account.createdAt)
            // Bound both positive and negative totals so balance calculations are safe in any order.
            var incoming = 0
            var outgoing = 0
            for wallet in account.wallets {
                guard walletIDs.insert(wallet.id).inserted,
                      !wallet.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { throw BackupError.invalidData }
                try Self.validateDate(wallet.createdAt)
                for transaction in wallet.transactions {
                    guard transactionIDs.insert(transaction.id).inserted, transaction.amount > 0
                    else { throw BackupError.invalidData }
                    try Self.validateDate(transaction.date)
                    switch transaction.type {
                    case .deposit, .transferIn:
                        incoming = try Self.add(incoming, transaction.amount)
                    case .withdrawal, .transferOut:
                        outgoing = try Self.add(outgoing, transaction.amount)
                    }
                    switch transaction.type {
                    case .transferIn, .transferOut:
                        guard let pairID = transaction.transferPairID else { throw BackupError.invalidTransfers }
                        pairs[pairID, default: []].append((transaction, account.id, wallet.id))
                    case .deposit, .withdrawal:
                        guard transaction.transferPairID == nil else { throw BackupError.invalidTransfers }
                    }
                }
            }
        }
        for pair in pairs.values {
            guard pair.count == 2,
                  pair[0].transaction.type != pair[1].transaction.type,
                  pair[0].transaction.amount == pair[1].transaction.amount,
                  pair[0].accountID == pair[1].accountID,
                  pair[0].walletID != pair[1].walletID else { throw BackupError.invalidTransfers }
        }
        if let selectedAccountID {
            guard let account = accounts.first(where: { $0.id == selectedAccountID })
            else { throw BackupError.invalidData }
            if let selectedWalletID, !account.wallets.contains(where: { $0.id == selectedWalletID }) {
                throw BackupError.invalidData
            }
        } else if selectedWalletID != nil {
            throw BackupError.invalidData
        }
    }

    private static func add(_ lhs: Int, _ rhs: Int) throws -> Int {
        let result = lhs.addingReportingOverflow(rhs)
        guard !result.overflow else { throw BackupError.invalidData }
        return result.partialValue
    }

    private static func validateDate(_ date: Date) throws {
        guard date.timeIntervalSince1970.isFinite, date >= .distantPast, date <= .distantFuture
        else { throw BackupError.invalidData }
    }
}

nonisolated enum BackupError: LocalizedError {
    case invalidFile
    case unsupportedVersion
    case invalidData
    case invalidTransfers
    case fileTooLarge
    case incompleteData

    var errorDescription: String? {
        switch self {
        case .invalidFile:
            "FamiBankのバックアップファイルを読み込めませんでした。書き出したJSONファイルを選んでください。"
        case .unsupportedVersion:
            "このバックアップの形式には対応していません。FamiBankを最新版に更新してください。"
        case .invalidData:
            "バックアップ内の名前・金額・日時・識別情報に不整合があります。元の端末で書き出し直してください。"
        case .invalidTransfers:
            "振替元と振替先の履歴が一致しません。元の端末でバックアップを書き出し直してください。"
        case .fileTooLarge:
            "バックアップファイルは20MB以内のものを選んでください。"
        case .incompleteData:
            "子供・口座・取引履歴の関連付けを確認できないため、バックアップを作成できませんでした。"
        }
    }
}
