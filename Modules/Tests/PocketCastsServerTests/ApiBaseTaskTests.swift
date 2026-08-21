@testable import PocketCastsServer
@testable import PocketCastsDataModel
@testable import PocketCastsUtils
import XCTest
import GRDB

final class ApiBaseTaskTests: XCTestCase {
    private var dataManager: DataManager!

    override func setUp() {
        dataManager = DataManager(dbQueue: GRDBQueue(dbPool: try! DatabasePool(path: NSTemporaryDirectory().appending("\(UUID().uuidString).sqlite"))))
    }

    override func tearDown() {
        FeatureFlagMock().reset()
    }

    func testTaskStartsAsynchronouslyWhenFlagIsEnabled() {
        FeatureFlagMock().set(.asyncApiTasks, value: true)

        let task = GatedTask(dataManager: dataManager)
        XCTAssertTrue(task.isAsynchronous)

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperation(task)

        wait(for: [task.didStart], timeout: 5)

        // the work hasn't completed, so the operation is still executing and holds up the queue
        XCTAssertTrue(task.isExecuting)
        XCTAssertFalse(task.isFinished)

        task.finishWork()
        queue.waitUntilAllOperationsAreFinished()

        XCTAssertFalse(task.isExecuting)
        XCTAssertTrue(task.isFinished)
    }

    func testStartDoesNotBlockTheCallingThreadWhenFlagIsEnabled() {
        FeatureFlagMock().set(.asyncApiTasks, value: true)

        let task = GatedTask(dataManager: dataManager)
        task.start()

        // start() returns while the task is still running its work
        XCTAssertFalse(task.isFinished)

        task.finishWork()
        wait(for: [task.didFinish], timeout: 5)
        XCTAssertTrue(task.isFinished)
    }

    func testTaskRunsSynchronouslyWhenFlagIsDisabled() {
        FeatureFlagMock().set(.asyncApiTasks, value: false)

        let task = GatedTask(dataManager: dataManager, opensGateOnStart: true)
        XCTAssertFalse(task.isAsynchronous)

        task.start()

        // with the flag off start() only returns once the work has completed
        XCTAssertTrue(task.didRunToCompletion)
        XCTAssertTrue(task.isFinished)
    }

    func testCancelledTaskFinishesWithoutRunning() {
        FeatureFlagMock().set(.asyncApiTasks, value: true)

        let task = GatedTask(dataManager: dataManager)
        task.cancel()
        task.start()

        XCTAssertTrue(task.isFinished)
        XCTAssertFalse(task.isExecuting)
        XCTAssertFalse(task.didRunToCompletion)
    }

    func testSerialQueueRunsAsyncTasksOneAtATime() {
        FeatureFlagMock().set(.asyncApiTasks, value: true)

        let first = GatedTask(dataManager: dataManager)
        let second = GatedTask(dataManager: dataManager)

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.addOperation(first)
        queue.addOperation(second)

        wait(for: [first.didStart], timeout: 5)
        XCTAssertFalse(second.isExecuting, "The second task shouldn't start until the first one has finished")

        first.finishWork()
        wait(for: [second.didStart], timeout: 5)

        second.finishWork()
        queue.waitUntilAllOperationsAreFinished()
    }

    func testPostToServerReturnsTheServerResponse() async {
        let responseData = Data("response".utf8)
        let task = ApiBaseTask(dataManager: dataManager, urlConnection: URLConnection(mockHandler: { request in
            (responseData, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil))
        }))

        let (data, httpStatus) = await task.postToServer(url: "\(ServerConstants.Urls.api())test", token: "token", data: Data())

        XCTAssertEqual(data, responseData)
        XCTAssertEqual(httpStatus, ServerConstants.HttpConstants.ok)
    }

    func testGetToServerReturnsTheServerResponse() async {
        let responseData = Data("response".utf8)
        let task = ApiBaseTask(dataManager: dataManager, urlConnection: URLConnection(mockHandler: { request in
            (responseData, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil))
        }))

        let (data, response) = await task.getToServer(url: "\(ServerConstants.Urls.api())test", token: "token")

        XCTAssertEqual(data, responseData)
        XCTAssertEqual(response?.statusCode, ServerConstants.HttpConstants.ok)
    }

    func testFailedRequestIsReportedAsAServerError() async {
        let task = ApiBaseTask(dataManager: dataManager, urlConnection: URLConnection(mockHandler: { _ in
            throw URLError(.notConnectedToInternet)
        }))

        let (data, httpStatus) = await task.postToServer(url: "\(ServerConstants.Urls.api())test", token: "token", data: Data())

        XCTAssertNil(data)
        XCTAssertEqual(httpStatus, ServerConstants.HttpConstants.serverError)
    }
}

/// A task whose work only completes once the test opens the gate
private final class GatedTask: ApiBaseTask, @unchecked Sendable {
    let didStart = XCTestExpectation(description: "Task started")
    let didFinish = XCTestExpectation(description: "Task finished")

    private(set) var didRunToCompletion = false

    private let gate = AsyncGate()
    private let opensGateOnStart: Bool

    init(dataManager: DataManager, opensGateOnStart: Bool = false) {
        self.opensGateOnStart = opensGateOnStart

        super.init(dataManager: dataManager, urlConnection: URLConnection(mockHandler: { _ in (nil, nil) }))
    }

    func finishWork() {
        gate.open()
    }

    override func runTask() async {
        if opensGateOnStart {
            gate.open()
        }

        didStart.fulfill()
        await gate.opened()
        didRunToCompletion = true
        didFinish.fulfill()
    }
}

private final class AsyncGate: @unchecked Sendable {
    private let lock = NSLock()
    private var isOpen = false
    private var continuation: CheckedContinuation<Void, Never>?

    func opened() async {
        await withCheckedContinuation { continuation in
            lock.lock()
            if isOpen {
                lock.unlock()
                continuation.resume()

                return
            }

            self.continuation = continuation
            lock.unlock()
        }
    }

    func open() {
        lock.lock()
        isOpen = true
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()

        continuation?.resume()
    }
}
