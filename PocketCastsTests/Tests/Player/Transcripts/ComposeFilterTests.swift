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

    func testSpeakerX() throws {
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

    func testTags() {
        let transcript = """
        <v Gabrielle Mérite>Especially when we make guidelines that are going to be used potentially by
        <v Gabrielle Mérite>hundreds of people, we have such a responsibility to do them properly.
        <v Moritz Stefaner>Hi everyone, welcome to a new episode of Data Stories. My name is Moritz Stefano
        <v Moritz Stefaner>and I'm an independent designer of data visualizations.
        <v Moritz Stefaner>In fact, I work as a self-employed truth and beauty operator out of my office
        <v Moritz Stefaner>here in the countryside in the north of Germany.
        <v Moritz Stefaner>And usually I record this podcast together with Enrico Bertini,
        <v Moritz Stefaner>who is a professor at Northeastern University in Boston. But today I'm solo.
        """

        let filtered = ComposeFilter.transcriptFilter.filter(transcript)

        let expected = """
        Especially when we make guidelines that are going to be used potentially by
        hundreds of people, we have such a responsibility to do them properly.
        Hi everyone, welcome to a new episode of Data Stories. My name is Moritz Stefano
        and I\'m an independent designer of data visualizations.
        In fact, I work as a self-employed truth and beauty operator out of my office
        here in the countryside in the north of Germany.
        And usually I record this podcast together with Enrico Bertini,
        who is a professor at Northeastern University in Boston. But today I\'m solo.
        """

        XCTAssertEqual(filtered, expected.trim())
    }

}
