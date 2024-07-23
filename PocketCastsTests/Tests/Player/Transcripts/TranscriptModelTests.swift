import XCTest

@testable import podcasts

final class TrasnscriptModelFilterTests: XCTestCase {

    func testVTT() throws {
        let transcript = """
        WEBVTT - Flying Too High: AI and Air France Flight 447

        0:00:15.410 --> 0:00:25.850
        <v Speaker 1>Pushkin. When the trouble started in the middle of the Atlantic,

        0:00:26.530 --> 0:00:30.650
        <v Speaker 1>Captain Mark Dubois was in the flight rest compartment, right

        0:00:30.690 --> 0:00:33.130
        <v Speaker 1>next to the flight deck. He was in charge of

        0:00:33.330 --> 0:00:37.690
        <v Speaker 1>Air France flight four four seven, en route overnight from

        0:00:37.770 --> 0:00:41.610
        <v Speaker 1>Rio de Janeiro to Paris, but he was tired. He

        0:00:41.610 --> 0:00:44.490
        <v Speaker 1>had been seeing the sights of Rio with his girlfriend

        0:00:45.050 --> 0:00:49.050
        <v Speaker 1>Copacabana Beach a helicopter tour, and he hadn\'t had a

        0:00:49.050 --> 0:00:52.450
        <v Speaker 1>lot of sleep. The airliner was in the hands of

        0:00:52.610 --> 0:00:57.850
        <v Speaker 1>flight officers David Robert and Pierre Cedric Bonard, and when

        0:00:57.850 --> 0:01:02.530
        <v Speaker 1>the trouble started, first Officer David Robert pressed the call

        0:01:02.610 --> 0:01:07.610
        <v Speaker 1>button to summon Captain Dubois. When you\'re asleep and the

        0:01:07.650 --> 0:01:11.810
        <v Speaker 1>alarm goes off, how quickly do you wake up? Captain

        0:01:11.890 --> 0:01:15.490
        <v Speaker 1>Dubois took ninety eight seconds to get out of bed

        0:01:16.010 --> 0:01:22.050
        <v Speaker 1>into the flight deck, not exactly slow, but not quick enough.
        """

        guard let model = TranscriptModel.makeModel(from: transcript, format: .vtt) else {
            XCTFail("Model should be created")
            return
        }
        let filtered = model.attributedText.string

        let expected = """
        Pushkin.
        When the trouble started in the middle of the Atlantic, Captain Mark Dubois was in the flight rest compartment, right next to the flight deck.
        He was in charge of Air France flight four four seven, en route overnight from Rio de Janeiro to Paris, but he was tired.
        He had been seeing the sights of Rio with his girlfriend Copacabana Beach a helicopter tour, and he hadn\'t had a lot of sleep.
        The airliner was in the hands of flight officers David Robert and Pierre Cedric Bonard, and when the trouble started, first Officer David Robert pressed the call button to summon Captain Dubois.
        When you\'re asleep and the alarm goes off, how quickly do you wake up?
        Captain Dubois took ninety eight seconds to get out of bed into the flight deck, not exactly slow, but not quick enough.
        """
        XCTAssertEqual(filtered.trim(), expected)
    }

    func testSRT() throws {
        let transcript = """
        1
        00:00:15,410 --> 00:00:29,130
        Speaker 1: Pushkin eighteen nineteen. The Pacific Ocean. The Pacific is pretty big,

        2
        00:00:29,370 --> 00:00:32,810
        Speaker 1: so let's narrow it down. We're close to the equator.

        3
        00:00:33,210 --> 00:00:38,250
        Speaker 1: Three thousand miles one way lies Ecuador, seven thousand miles

        4
        00:00:38,290 --> 00:00:42,250
        Speaker 1: the other way Papua New Guinea. Your nearest land is

        5
        00:00:42,290 --> 00:00:46,530
        Speaker 1: a small volcano in what's now French Polynesia. And when

        6
        00:00:46,570 --> 00:00:51,930
        Speaker 1: I say nearest, I'm talking fifteen one hundred miles. You

        7
        00:00:51,970 --> 00:00:56,530
        Speaker 1: get the idea. We're a very long way from anywhere.
        """

        guard let model = TranscriptModel.makeModel(from: transcript, format: .srt) else {
            XCTFail("Model should be created")
            return
        }
        let filtered = model.attributedText.string

        let expected = """
        Pushkin eighteen nineteen.
        The Pacific Ocean.
        The Pacific is pretty big, so let's narrow it down.
        We're close to the equator.
        Three thousand miles one way lies Ecuador, seven thousand miles the other way Papua New Guinea.
        Your nearest land is a small volcano in what's now French Polynesia.
        And when I say nearest, I'm talking fifteen one hundred miles.
        You get the idea.
        We're a very long way from anywhere.
        """

        XCTAssertEqual(filtered.trim(), expected)
    }

}
