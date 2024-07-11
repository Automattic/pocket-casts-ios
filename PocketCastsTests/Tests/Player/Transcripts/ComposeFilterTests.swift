import XCTest

@testable import podcasts

final class ComposeFilterTests: XCTestCase {

    func testNormalString() throws {
        let transcript = """
        This content should not change
        """

        let filtered = ComposeFilter.transcriptFilter.filter(transcript)

        XCTAssertEqual(filtered, "This content should not change")
    }

    func testVTT() throws {
        let transcript = """
        Speaker 1: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus imperdiet condimentum ligula quis fringilla. Donec eu ultricies enim. Aenean eu risus leo. Nulla facilisi.

        Speaker 2: Mauris ac urna sodales, efficitur ipsum congue, congue arcu. Nam ut lacus eget urna vehicula dictum eget vel mauris.

        Speaker 1: Aenean quis commodo est, a faucibus ligula. Vivamus ultricies lectus ut dui varius, nec mollis sapien elementum. Phasellus augue arcu, tincidunt fermentum justo ullamcorper,

        Speaker 1: tincidunt scelerisque libero. Cras maximus nunc consectetur, scelerisque tortor at, aliquet metus. Aliquam ullamcorper in massa in convallis.
        """

        let filtered = ComposeFilter.transcriptFilter.filter(transcript)

        let expected = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus imperdiet condimentum ligula quis fringilla. Donec eu ultricies enim. Aenean eu risus leo. Nulla facilisi.

         Mauris ac urna sodales, efficitur ipsum congue, congue arcu. Nam ut lacus eget urna vehicula dictum eget vel mauris.

         Aenean quis commodo est, a faucibus ligula. Vivamus ultricies lectus ut dui varius, nec mollis sapien elementum. Phasellus augue arcu, tincidunt fermentum justo ullamcorper,

         tincidunt scelerisque libero. Cras maximus nunc consectetur, scelerisque tortor at, aliquet metus. Aliquam ullamcorper in massa in convallis.
        """

        XCTAssertEqual(filtered, expected.trim())
    }

}
