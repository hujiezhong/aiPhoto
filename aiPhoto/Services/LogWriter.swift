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

    private func todayFileURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let filename = "\(formatter.string(from: Date())).log"
        return directory.appendingPathComponent(filename)
    }

    private func format(level: Level, message: String, context: [String: String]?) -> String {
        let ts = ISO8601DateFormatter().string(from: Date())
        var line = "\(ts) [\(level.rawValue.uppercased())] \(message)"
        if let context = context, !context.isEmpty {
            let ctx = context.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
            line += " | \(ctx)"
        }
        return line
    }
}
