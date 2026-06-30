import Foundation

final class LogWriter {
    enum Level: String { case debug, info, warn, error }

    let directory: URL
    let retentionDays: Int
    private let queue = DispatchQueue(label: "logwriter", qos: .utility)

    init(directory: URL, retentionDays: Int = 7) {
        self.directory = directory
        self.retentionDays = retentionDays
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func write(level: Level, message: String, context: [String: String]?) throws {
        let line = format(level: level, message: message, context: context)
        let fileURL = todayFileURL()
        queue.sync {
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            }
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                defer { try? handle.close() }
                try? handle.seekToEnd()
                if let data = (line + "\n").data(using: .utf8) {
                    try? handle.write(contentsOf: data)
                }
            }
        }
    }

    func cleanup() throws {
        let cutoff = Date().addingTimeInterval(-Double(retentionDays) * 86400)
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey])
        for file in files {
            let values = try file.resourceValues(forKeys: [.contentModificationDateKey])
            if let mtime = values.contentModificationDate, mtime < cutoff {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private func todayFileURL() -> URL {
        let filename = "\(Self.dayFormatter.string(from: Date())).log"
        return directory.appendingPathComponent(filename)
    }

    private func format(level: Level, message: String, context: [String: String]?) -> String {
        let ts = Self.iso8601.string(from: Date())
        var line = "\(ts) [\(level.rawValue.uppercased())] \(message)"
        if let context = context, !context.isEmpty {
            let ctx = context.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
            line += " | \(ctx)"
        }
        return line
    }
}
