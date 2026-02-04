import Foundation
import GRDB
@testable import PocketCastsDataModel

/// Container to capture SQL from GRDB operations
/// Uses a shared mutable reference that can be passed to the database configuration
class SQLCaptureContainer {
    var capturedSQL: [String] = []

    /// Returns the last SELECT or COUNT query captured
    var lastQuerySQL: String? {
        capturedSQL.last { sql in
            let upper = sql.uppercased()
            return upper.hasPrefix("SELECT")
        }
    }

    func clear() {
        capturedSQL.removeAll()
    }
}

/// A GRDBQueue wrapper that captures executed SQL for testing
/// Uses a custom DatabasePool with tracing enabled
class SQLCapturingGRDBQueue: GRDBQueue {
    let captureContainer: SQLCaptureContainer
    private let tempFileURL: URL

    var capturedSQL: [String] {
        captureContainer.capturedSQL
    }

    /// Returns the last SELECT query captured (ignores transaction statements)
    var lastCapturedSQL: String? {
        captureContainer.lastQuerySQL
    }

    init() throws {
        let container = SQLCaptureContainer()
        self.captureContainer = container

        // Create a temporary file for the database (DatabasePool requires WAL mode which doesn't work with :memory:)
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).sqlite")
        self.tempFileURL = tempFile

        // Create a configuration that enables SQL tracing
        var config = Configuration()
        config.prepareDatabase { db in
            db.trace { event in
                if case let .statement(statement) = event {
                    container.capturedSQL.append(statement.expandedSQL)
                }
            }
        }
        let dbPool = try DatabasePool(path: tempFile.path, configuration: config)
        super.init(dbPool: dbPool, logger: nil)
    }

    deinit {
        // Clean up temporary database file
        try? FileManager.default.removeItem(at: tempFileURL)
    }

    func clearCapturedSQL() {
        captureContainer.clear()
    }
}
