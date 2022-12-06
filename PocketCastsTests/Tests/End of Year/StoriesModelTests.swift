import XCTest
import SwiftUI

@testable import podcasts

@MainActor
class StoriesModelTests: XCTestCase {
    func testCurrentStoryAndProgressStartsInZero() {
        let model = StoriesModel(dataSource: MockStoriesDataSource(),
                                 configuration: StoriesConfiguration())

        XCTAssertEqual(model.currentStory, 0)
        XCTAssertEqual(model.progress, 0)
    }

    func testNumberOfStoriesReflectDataSourceValue() {
        let model = StoriesModel(dataSource: MockStoriesDataSource(),
                                 configuration: StoriesConfiguration())

        XCTAssertEqual(model.numberOfStories, 2)
    }

    func testProgressChangesAfterStart() {
        let model = StoriesModel(dataSource: MockStoriesDataSource(),
                                 configuration: StoriesConfiguration())

        model.start()

        eventually {
            XCTAssertTrue(model.progress > 0)
        }
    }

    func testNext() {
        let model = StoriesModel(dataSource: MockStoriesDataSource(),
                                 configuration: StoriesConfiguration())
        model.start()

        model.next()

        eventually {
            XCTAssertEqual(model.currentStory, 1)
        }
    }

    func testPrevious() {
        let model = StoriesModel(dataSource: MockStoriesDataSource(),
                                 configuration: StoriesConfiguration())
        model.start()
        model.next()

        model.previous()

        eventually {
            XCTAssertEqual(model.currentStory, 0)
        }
    }

    func testWhenCallingStoryTheDataSourceIsCalledForTheView() {
        let dataSource = MockStoriesDataSource()
        let model = StoriesModel(dataSource: dataSource,
                                 configuration: StoriesConfiguration())

        _ = model.story(index: 0)

        XCTAssertEqual(dataSource.didCallStoryForWithStoryNumber, 0)
    }
}

class MockStoriesDataSource: StoriesDataSource {
    var numberOfStories: Int = 2

    var didCallStoryForWithStoryNumber: Int?

    func story(for storyNumber: Int) -> any StoryView {
        didCallStoryForWithStoryNumber = storyNumber

        switch storyNumber {
        case 0:
            return MockedStory()
        default:
            return MockedStoryTwo()
        }
    }

    func shareableStory(for storyNumber: Int) -> (any ShareableStory)? {
        nil
    }

    func isReady() async -> Bool {
        true
    }
}

struct MockedStory: StoryView {
    var duration: TimeInterval = 5 * 60

    var body: some View {
        ZStack {
            Color.purple
        }
    }
}

struct MockedStoryTwo: StoryView {
    var duration: TimeInterval = 5 * 60

    var body: some View {
        ZStack {
            Color.yellow
        }
    }
}
