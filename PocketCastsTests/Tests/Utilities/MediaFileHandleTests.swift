import XCTest
@testable import podcasts

final class MediaFileHandleTests: XCTestCase {

    var tempFilePath: String!
    var sut: MediaFileHandle!

    override func setUp() {
        super.setUp()
        tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString + "_test.media")
        sut = MediaFileHandle(filePath: tempFilePath)
    }

    override func tearDown() {
        sut.close()
        sut = nil
        try? FileManager.default.removeItem(atPath: tempFilePath)
        tempFilePath = nil
        super.tearDown()
    }

    // MARK: - throwableFileSize

    func testThrowableFileSize_returnsZeroForNewFile() throws {
        let size = try sut.throwableFileSize()
        XCTAssertEqual(size, 0)
    }

    func testThrowableFileSize_returnsCorrectSizeAfterWrite() throws {
        let data = Data(repeating: 0xAB, count: 1024)
        try sut.append(data: data)
        sut.synchronize()

        let size = try sut.throwableFileSize()
        XCTAssertEqual(size, 1024)
    }

    func testThrowableFileSize_throwsWhenFileIsDeleted() throws {
        try FileManager.default.removeItem(atPath: tempFilePath)

        XCTAssertThrowsError(try sut.throwableFileSize(), "throwableFileSize should throw when the file no longer exists")
    }

    // MARK: - readData

    func testReadData_returnsCorrectDataFromFile() throws {
        let original = Data("hello podcast".utf8)
        try sut.append(data: original)
        sut.synchronize()

        let read = try sut.readData(withOffset: 0, forLength: original.count)
        XCTAssertEqual(read, original)
    }

    func testReadData_returnsCorrectDataWithOffset() throws {
        let original = Data("abcdefghij".utf8)
        try sut.append(data: original)
        sut.synchronize()

        let read = try sut.readData(withOffset: 5, forLength: 3)
        XCTAssertEqual(read, Data("fgh".utf8))
    }

    func testReadData_throwsUnableToOpenFile_afterHandleIsClosed() {
        sut.close()

        XCTAssertThrowsError(try sut.readData(withOffset: 0, forLength: 10)) { error in
            XCTAssertEqual(error as? MediaFileHandleError, .unableToOpenFile,
                           "Expected .unableToOpenFile when file handle has been closed")
        }
    }

    func testReadData_throwsUnableToOpenFile_whenFileDeletedBeforeFirstAccess() throws {
        // readHandle is a lazy var — it's only initialized on the first access.
        // Deleting the file before that first access means FileHandle(forReadingAtPath:)
        // returns nil, so readData should throw .unableToOpenFile.
        let path = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString + "_lazy.media")
        let handle = MediaFileHandle(filePath: path)
        defer { try? FileManager.default.removeItem(atPath: path) }

        try FileManager.default.removeItem(atPath: path)

        XCTAssertThrowsError(try handle.readData(withOffset: 0, forLength: 10)) { error in
            XCTAssertEqual(error as? MediaFileHandleError, .unableToOpenFile,
                           "Expected .unableToOpenFile when underlying file is gone before first read")
        }
    }
}
