import XCTest
import SwiftUI

@testable import podcasts

@MainActor
class StoriesModelTests: XCTestCase {
    func testCurrentStoryAndProgressStartsInZero() {
        let model = StoriesModel(dataSource: MockStoriesDataSource())

        XCTAssertEqual(model.currentStory, 0)
        XCTAssertEqual(model.progress, 0)
    }

    func testNumberOfStoriesReflectDataSourceValue() {
        let model = StoriesModel(dataSource: MockStoriesDataSource())

        XCTAssertEqual(model.numberOfStories, 2)
    }

    func testProgressChangesAfterStart() {
        let model = StoriesModel(dataSource: MockStoriesDataSource())

        model.start()

        eventually {
            XCTAssertTrue(model.progress > 0)
        }
    }

    func testNext() {
        let model = StoriesModel(dataSource: MockStoriesDataSource())
        model.start()

        model.next()

        eventually {
            XCTAssertEqual(model.currentStory, 1)
        }
    }

    func testPrevious() {
        let model = StoriesModel(dataSource: MockStoriesDataSource())
        model.start()
        model.next()

        model.previous()

        eventually {
            XCTAssertEqual(model.currentStory, 0)
        }
    }

    func testWhenCallingStoryTheDataSourceIsCalledForTheView() {
        let dataSource = MockStoriesDataSource()
        let model = StoriesModel(dataSource: dataSource)

        _ = model.story(index: 0)

        XCTAssertEqual(dataSource.didCallStoryForWithStoryNumber, 0)
    }
}

class MockStoriesDataSource: StoriesDataSource {
    var numberOfStories: Int = 2

    var didCallStoryForWithStoryNumber: Int?

    func story(for storyNumber: Int) -> any View {
        didCallStoryForWithStoryNumber = storyNumber

        switch storyNumber {
        case 0:
            return FakeStory()
        default:
            return FakeStoryTwo()
        }
    }

    func isReady() async -> Bool {
        true
    }
}

struct MockedStory: View {
    var body: some View {
        ZStack {
            Color.purple
        }
    }
}

struct MockedStoryTwo: View {
    var body: some View {
        ZStack {
            Color.yellow
        }
    }
}
