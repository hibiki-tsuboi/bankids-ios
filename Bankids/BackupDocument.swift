import SwiftUI
import UniformTypeIdentifiers

nonisolated struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw BackupError.invalidFile }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }

    static func readArchive(from url: URL) throws -> BackupArchive {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
        var coordinationError: NSError?
        var result: Result<BackupArchive, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { readingURL in
            result = Result {
                let file = try FileHandle(forReadingFrom: readingURL)
                defer { try? file.close() }
                var data = Data()
                while let chunk = try file.read(upToCount: min(65_536, BackupArchive.maximumFileSize + 1 - data.count)),
                      !chunk.isEmpty {
                    data.append(chunk)
                    guard data.count <= BackupArchive.maximumFileSize else { throw BackupError.fileTooLarge }
                }
                return try BackupArchive.decode(data)
            }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw BackupError.invalidFile }
        return try result.get()
    }
}
