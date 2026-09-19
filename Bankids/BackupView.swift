import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AccountManager.self) private var accountManager
    @Query private var accounts: [Account]

    @State private var document: BackupDocument?
    @State private var filename = "FamiBank-backup"
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var pendingArchive: BackupArchive?
    @State private var showingRestoreConfirmation = false
    @State private var isWorking = false
    @State private var feedback: Feedback?

    private struct Feedback: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        var didRestore = false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("機種変更の前に、大切な記録を保存", systemImage: "externaldrive.badge.icloud")
                        .font(.headline)
                        .foregroundStyle(Color("PrimaryBlue"))
                    Text("すべての子供・口座・取引履歴・メモをまとめて保存し、別のiPhoneで復元できます。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button(action: exportBackup) {
                        Label("バックアップを書き出す", systemImage: "square.and.arrow.up")
                    }
                    .disabled(accounts.isEmpty)
                } header: {
                    Text("今のデータを保存")
                } footer: {
                    Text("「ファイル」に保存できます。保存したファイルは「ファイル」アプリからAirDropで送れます。名前や取引履歴を含むため、保存先と共有相手をご確認ください。ファイルは暗号化されません。")
                }

                Section {
                    Button {
                        pendingArchive = nil
                        showingImporter = true
                    } label: {
                        Label("バックアップを選ぶ", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("別の端末のデータを復元")
                } footer: {
                    Text("FamiBankで書き出したJSONファイルを選んでください。内容を確認するまで、現在のデータは変更されません。")
                }

                if let archive = pendingArchive {
                    Section("復元する内容") {
                        LabeledContent("バックアップ日時") {
                            Text(archive.exportedAt, format: .dateTime.year().month().day().hour().minute())
                        }
                        LabeledContent("子供", value: "\(archive.accounts.count)人")
                        LabeledContent("口座", value: "\(archive.walletCount)件")
                        LabeledContent("取引履歴", value: "\(archive.transactionCount)件")
                        ForEach(archive.accounts) { account in
                            LabeledContent(account.name, value: "¥\(account.balance.formatted())")
                        }
                    }
                    Section {
                        Button("このバックアップで復元する", role: .destructive) {
                            showingRestoreConfirmation = true
                        }
                        Button("選択を取り消す") {
                            pendingArchive = nil
                        }
                    } footer: {
                        Text("このiPhoneにあるすべての子供・口座・取引履歴を置き換えます。今の記録も残したい場合は、先にバックアップを書き出してください。")
                    }
                }

                if isWorking {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("処理中…")
                            Spacer()
                        }
                    }
                }
            }
            .disabled(isWorking)
            .navigationTitle("バックアップと復元")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") { dismiss() }
                        .disabled(isWorking)
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: document,
                contentType: .json,
                defaultFilename: filename
            ) { result in
                document = nil
                switch result {
                case .success:
                    feedback = Feedback(title: "保存しました", message: "新しいiPhoneでこのファイルを選び、バックアップから復元してください。")
                case .failure(let error):
                    showError(error, title: "保存できませんでした")
                }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    readBackup(url)
                case .failure(let error):
                    showError(error, title: "読み込めませんでした")
                }
            }
            .alert("現在のデータを置き換えますか？", isPresented: $showingRestoreConfirmation) {
                Button("すべて置き換えて復元", role: .destructive, action: restoreBackup)
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("このiPhoneのデータを削除し、選択したバックアップの内容に置き換えます。元の端末のデータは変更されません。")
            }
            .alert(item: $feedback) { feedback in
                Alert(
                    title: Text(feedback.title), message: Text(feedback.message),
                    dismissButton: .default(Text("OK")) {
                        if feedback.didRestore { dismiss() }
                    }
                )
            }
        }
        .tint(Color("PrimaryBlue"))
        .interactiveDismissDisabled(isWorking)
    }

    private func exportBackup() {
        isWorking = true
        Task { @MainActor in
            defer { isWorking = false }
            do {
                let archive = try BackupService.makeArchive(in: modelContext, accountManager: accountManager)
                let data = try await Task.detached { try archive.encoded() }.value
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyyMMdd-HHmmss"
                filename = "FamiBank-backup-\(formatter.string(from: archive.exportedAt))"
                document = BackupDocument(data: data)
                showingExporter = true
            } catch {
                showError(error, title: "書き出せませんでした")
            }
        }
    }

    private func readBackup(_ url: URL) {
        isWorking = true
        Task { @MainActor in
            defer { isWorking = false }
            do {
                pendingArchive = try await Task.detached { try BackupDocument.readArchive(from: url) }.value
            } catch {
                showError(error, title: "読み込めませんでした")
            }
        }
    }

    private func restoreBackup() {
        guard let archive = pendingArchive else { return }
        isWorking = true
        Task { @MainActor in
            defer { isWorking = false }
            await Task.yield()
            do {
                try BackupService.restore(archive, in: modelContext, accountManager: accountManager)
                pendingArchive = nil
                feedback = Feedback(
                    title: "復元しました",
                    message: "子供\(archive.accounts.count)人・口座\(archive.walletCount)件・取引履歴\(archive.transactionCount)件を復元しました。残高と履歴をご確認ください。",
                    didRestore: true
                )
            } catch {
                feedback = Feedback(title: "復元できませんでした", message: "現在のデータは保持されています。\n\(error.localizedDescription)")
            }
        }
    }

    private func showError(_ error: Error, title: String) {
        let nsError = error as NSError
        guard nsError.domain != NSCocoaErrorDomain || nsError.code != NSUserCancelledError else { return }
        feedback = Feedback(title: title, message: error.localizedDescription)
    }
}
