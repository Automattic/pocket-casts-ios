import XCTest

@testable import podcasts

final class TranscriptModelFilterTests: XCTestCase {

    func testVTT() throws {
        let transcript = """
        WEBVTT - Lorem ipsum translated to English

        0:00:15.410 --> 0:00:25.850
        <v Speaker 1>But I must explain to you how all this mistaken idea

        0:00:26.530 --> 0:00:30.650
        <v Speaker 1>of reprobating pleasure and extolling pain arose. To do so, I will give you a complete account of the system,

        0:00:30.690 --> 0:00:33.130
        <v Speaker 1>and expound the actual teachings of the great explorer of the truth,

        0:00:33.330 --> 0:00:37.690
        <v Speaker 1>the master-builder of human happiness. No one rejects,

        0:00:37.770 --> 0:00:41.610
        <v Speaker 1>dislikes or avoids pleasure itself, because it is pleasure, but because

        0:00:41.610 --> 0:00:44.490
        <v Speaker 1>those who do not know how to pursue pleasure rationally encounter consequences

        0:00:45.050 --> 0:00:49.050
        <v Speaker 1>that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain

        0:00:49.050 --> 0:00:52.450
        <v Speaker 1>of itself, because it is pain, but occasionally circumstances occur in which toil and pain can procure

        0:00:52.610 --> 0:00:57.850
        <v Speaker 1>him some great pleasure. To take a trivial example, which of us ever undertakes laborious

        0:00:57.850 --> 0:01:02.530
        <v Speaker 1>physical exercise, except to obtain some advantage from it? But who has any right

        0:01:02.610 --> 0:01:07.610
        <v Speaker 1>to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences,

        0:01:07.650 --> 0:01:11.810
        <v Speaker 1>or one who avoids a pain

        0:01:11.890 --> 0:01:15.490
        <v Speaker 1>that produces no resultant pleasure?
        """

        guard let model = TranscriptModel.makeModel(from: transcript, format: .vtt) else {
            XCTFail("Model should be created")
            return
        }
        let filtered = model.attributedText.string

        let expected = """
        But I must explain to you how all this mistaken idea of reprobating pleasure and extolling pain arose.
        To do so, I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness.
        No one rejects, dislikes or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful.
        Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but occasionally circumstances occur in which toil and pain can procure him some great pleasure.
        To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it?
        But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?
        """
        XCTAssertEqual(filtered.trim(), expected)
    }

    func testSRT() throws {
        let transcript = """
        1
        0:00:15,410 --> 0:00:25,850
        Speaker 1: But I must explain to you how all this mistaken idea

        2
        0:00:26,530 --> 0:00:30,650
        Speaker 1: of reprobating pleasure and extolling pain arose. To do so, I will give you a complete account of the system,

        3
        0:00:30,690 --> 0:00:33,130
        Speaker 1: and expound the actual teachings of the great explorer of the truth,

        4
        0:00:33,330 --> 0:00:37,690
        Speaker 1: the master-builder of human happiness. No one rejects,

        5
        0:00:37,770 --> 0:00:41,610
        Speaker 1: dislikes or avoids pleasure itself, because it is pleasure, but because

        6
        0:00:41,610 --> 0:00:44,490
        Speaker 1: those who do not know how to pursue pleasure rationally encounter consequences

        7
        0:00:45,050 --> 0:00:49,050
        Speaker 1: that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain

        8
        0:00:49,050 --> 0:00:52,450
        Speaker 1: of itself, because it is pain, but occasionally circumstances occur in which toil and pain can procure

        9
        0:00:52,610 --> 0:00:57,850
        Speaker 1: him some great pleasure. To take a trivial example, which of us ever undertakes laborious

        10
        0:00:57,850 --> 0:01:02,530
        Speaker 1: physical exercise, except to obtain some advantage from it? But who has any right

        11
        0:01:02,610 --> 0:01:07,610
        Speaker 1: to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences,

        12
        0:01:07,650 --> 0:01:11,810
        Speaker 1: or one who avoids a pain

        13
        0:01:11,890 --> 0:01:15,490
        Speaker 1: that produces no resultant pleasure?
        """

        guard let model = TranscriptModel.makeModel(from: transcript, format: .srt) else {
            XCTFail("Model should be created")
            return
        }
        let filtered = model.attributedText.string

        let expected = """
        But I must explain to you how all this mistaken idea of reprobating pleasure and extolling pain arose.
        To do so, I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness.
        No one rejects, dislikes or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful.
        Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but occasionally circumstances occur in which toil and pain can procure him some great pleasure.
        To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it?
        But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?
        """

        XCTAssertEqual(filtered.trim(), expected)
    }

    func testHTML() throws {
        let transcript = """
        <p><!--block--><b>Peter:</b> How should we start?&nbsp;</p><p><!--block--><br><b>Mike:</b> I mean, we don't need a zing.&nbsp;</p><p><!--block--><br><b>Peter:</b> Michael, Peter, what do you know about the next Vice President of the United States?&nbsp;</p><p><!--block--><br><b>Mike:</b> I'm proud of his ad-Vance-ment.&nbsp;</p><p><!--block--><br></p><p><!--block--><b>Peter:</b> [laughs]&nbsp;</p><p><!--block--><br></p><p><!--block--><b>Mike:</b> Terrible.&nbsp;</p><p><!--block--><br><b>Peter:</b> Terrible. Oh, my God.&nbsp;</p><p><!--block--><br><b>Mike:</b> Ridiculous.&nbsp;</p><p><!--block--><br><b>Peter:</b> So we thought we would release our Hillbilly Elegy episode, now that the author, J. D. Vance, has been selected by Donald Trump as his running mate for the presidential election.&nbsp;</p><p><!--block--><br><b>Mike:</b> We have also been a little bit late with episodes lately because I got Covid and Peter got the Elden Ring DLC. [Peter chuckles] So we're doing this to hold you over until we're back with Jonathan Haidt's <em>Anxious Generation</em>. So please stop emailing us asking us to do it because we're already doing it.&nbsp;</p><p><!--block--><br></p>
        """

        guard let model = TranscriptModel.makeModel(from: transcript, format: .textHTML) else {
            XCTFail("Model should be created")
            return
        }
        let filtered = model.attributedText.string

        let expected = """
        Peter: How should we start?
        Mike: I mean, we don't need a zing.
        Peter: Michael, Peter, what do you know about the next Vice President of the United States?
        Mike: I'm proud of his ad-Vance-ment.
        Peter:
        Mike: Terrible.
        Peter: Terrible. Oh, my God.
        Mike: Ridiculous.
        Peter: So we thought we would release our Hillbilly Elegy episode, now that the author, J.D. Vance, has been selected by Donald Trump as his running mate for the presidential election.
        Mike: We have also been a little bit late with episodes lately because I got Covid and Peter got the Elden Ring DLC. So we're doing this to hold you over until we're back with Jonathan Haidt's Anxious Generation. So please stop emailing us asking us to do it because we're already doing it.
        """

        XCTAssertEqual(filtered.trim(), expected)
    }

}
