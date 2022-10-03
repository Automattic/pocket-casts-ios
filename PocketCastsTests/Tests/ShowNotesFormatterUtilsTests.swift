import Foundation
@testable import podcasts
import XCTest

class ShowNotesFormatterUtilsTests: XCTestCase {
    func test_convertToLinks() throws {
        var actual = ""
        var expected = ""

        // Existing Android test cases (for completeness)
        actual = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: "<p><strong>57:00</strong> - PDF Assets on iOS</p>")
        expected = "<p><strong><a href=\"http://localhost/#playerJumpTo=57:00\">57:00</a></strong> - PDF Assets on iOS</p>"
        XCTAssertEqual(actual, expected)

        actual = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: "<p><strong>6:20</strong> - How do you see the trend of designers moving from small agencies to product companies?</p>")
        expected = "<p><strong><a href=\"http://localhost/#playerJumpTo=6:20\">6:20</a></strong> - How do you see the trend of designers moving from small agencies to product companies?</p>"
        XCTAssertEqual(actual, expected)

        actual = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: "<p><strong>10:00</strong> - Getting work and creating products as an agency</p>")
        expected = "<p><strong><a href=\"http://localhost/#playerJumpTo=10:00\">10:00</a></strong> - Getting work and creating products as an agency</p>"
        XCTAssertEqual(actual, expected)

        actual = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: "Grizzlies win over the Timberwolves (8:52), from Anthony Davis (25:32), and the Lakers' new life without Kobe (35:35).")
        expected = "Grizzlies win over the Timberwolves (<a href=\"http://localhost/#playerJumpTo=8:52\">8:52</a>), from Anthony Davis (<a href=\"http://localhost/#playerJumpTo=25:32\">25:32</a>), and the Lakers' new life without Kobe (<a href=\"http://localhost/#playerJumpTo=35:35\">35:35</a>)."
        XCTAssertEqual(actual, expected)

        actual = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: "Grizzlies win over the Timberwolves (8:52, from Anthony Davis 25:32), and the Lakers' new life without Kobe (35:35).")
        expected = "Grizzlies win over the Timberwolves (<a href=\"http://localhost/#playerJumpTo=8:52\">8:52</a>, from Anthony Davis <a href=\"http://localhost/#playerJumpTo=25:32\">25:32</a>), and the Lakers' new life without Kobe (<a href=\"http://localhost/#playerJumpTo=35:35\">35:35</a>)."
        XCTAssertEqual(actual, expected)

        // Accidental Tech Podcast - https://nodeweb.pocketcasts.com/admin/podcasts/180561
        actual = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: "<li><a href=\"https://overcast.fm/+BtuyYAAIQ/16:45\">Confirmation of John's prediction about face swipe timing</a></li>")
        expected = "<li><a href=\"https://overcast.fm/+BtuyYAAIQ/16:45\">Confirmation of John's prediction about face swipe timing</a></li>"
        XCTAssertEqual(actual, expected)

        // Large show notes tests
        actual = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: "No timestamps in show notes")
        expected = "No timestamps in show notes"
        XCTAssertEqual(actual, expected)

        actual = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: "Only links in show notes <a href='https://www.pocketcasts.com'>Pocket Casts</a>")
        expected = "Only links in show notes <a href='https://www.pocketcasts.com'>Pocket Casts</a>"
        XCTAssertEqual(actual, expected)

        actual = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: """
        This is a block of html that I've crafted to find issues with my attempt at safe `a` tag detection

                <a href='https://www.automattic.com'>It contains</a> many links that are valid, <a href='https://www.pocketcasts.com'> that are
                broken across multiple lines</a>, and that are <a href='https://www.tsn.ca'>themselves <a href='https://www.cbcsports.ca'>invalid and nested</a> in an </a> attempt to confuse the regex `a` tag detection.

                <ul>
                <li>1:11 - a legit jump test</li>
                <li>2:22 - another legit jump test</li>
                <li><a href='https://www.johncaruso.ca'>Testing timestamps 11:13 in links - which shouldn't become jump to links, but still be proper HREFS</a></li>
                <li><a href='https://www.johncaruso.ca'>Links with <span style='font-weight: bold; color: purple'>tags</span> inside them</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 0</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 1</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 2</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 3</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 4</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 5</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 6</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 7</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 8</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 9</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 10</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 11</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 12</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 13</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 14</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 15</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 16</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 17</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 18</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 19</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 20</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 21</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 22</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 23</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 24</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 25</a></li>
                </ul>
        """)
        expected = """
        This is a block of html that I've crafted to find issues with my attempt at safe `a` tag detection

                <a href='https://www.automattic.com'>It contains</a> many links that are valid, <a href='https://www.pocketcasts.com'> that are
                broken across multiple lines</a>, and that are <a href='https://www.tsn.ca'>themselves <a href='https://www.cbcsports.ca'>invalid and nested</a> in an </a> attempt to confuse the regex `a` tag detection.

                <ul>
                <li><a href=\"http://localhost/#playerJumpTo=1:11\">1:11</a> - a legit jump test</li>
                <li><a href=\"http://localhost/#playerJumpTo=2:22\">2:22</a> - another legit jump test</li>
                <li><a href='https://www.johncaruso.ca'>Testing timestamps 11:13 in links - which shouldn't become jump to links, but still be proper HREFS</a></li>
                <li><a href='https://www.johncaruso.ca'>Links with <span style='font-weight: bold; color: purple'>tags</span> inside them</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 0</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 1</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 2</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 3</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 4</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 5</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 6</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 7</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 8</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 9</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 10</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 11</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 12</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 13</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 14</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 15</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 16</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 17</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 18</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 19</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 20</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 21</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 22</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 23</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 24</a></li>
                <li><a href='https://www.johncaruso.ca'>Testing more than 10 links to ensure text replacing works as expected 25</a></li>
                </ul>
        """
        XCTAssertEqual(actual, expected)

        // "Rebuild - Tatsuhiko Miyagawa" episode 325
        actual = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: """
        <html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-16le'><meta name='viewport' content='initial-scale=1.0' /><style type='text/css'>body { font-family: '-apple-system'; font-size: 16px; line-height: 22px; letter-spacing: -0.1px;background-color: transparent;color: #FFFFFF;margin: 8px 16px; word-wrap: break-word; } pre { white-space: pre-wrap; } a { color:#FFFFFF; font-family:'-apple-system'; text-decoration:underline; } h1,h2,h3,h4,h5,h6 { font-family: '-apple-system'; font-weight: normal; font-size: 16px; padding: 0; } img { width: auto !important; height: auto !important; max-width:100%; max-height: auto; padding-bottom: 10px; padding-top: 10px; display: block; } img[src*=\"coverart\" i] { display: none; } html { -webkit-text-size-adjust: none; } img[src*='feeds.feedburner.com'] { display: none; }</style></head><body><p>Kazuho Okui さんをゲストに迎えて、COVID-19, MacBook Pro, サバティカルなどについて話しました。</p>
        <h3>Show Notes</h3><ul><li><a href=\"https://sf.gov/data/covid-19-cases-and-deaths\">COVID-19 cases and deaths | San Francisco</a></li><li><a href=\"https://www.nbcnews.com/politics/white-house/biden-s-plan-free-home-covid-test-could-be-ineffective-n1285560\">Biden&#39;s plan for free at-home Covid test could be ineffective</a></li><li><a href=\"https://federalnewsnetwork.com/technology-main/2021/09/cbp-building-on-facial-recognition-successes-as-travelers-reap-benefits-of-expedited-process/\">CBP building on facial recognition successes as travelers reap benefits of expedited process</a></li><li><a href=\"https://developer.apple.com/documentation/authenticationservices/securing_logins_with_icloud_keychain_verification_codes\">Securing Logins with iCloud Keychain Verification Codes</a></li><li><a href=\"https://maestral.app/\">Maestral</a></li><li><a href=\"https://www.caldigit.com/thunderbolt-4-element-hub/\">Thunderbolt 4 | USB4 | Element Hub</a></li><li><a href=\"https://www.amazon.com/Anker-Charger-PowerPort-Charging-Station/dp/B09J1XTLJ6?&amp;linkCode&#61;ll1&amp;tag&#61;bulknewstypep-20\">Anker USB C Charger 120W, 547 Charger, PowerPort III 4-Port Charging Station</a></li><li><a href=\"https://www.caseyliss.com/2021/12/7/monitor-liss\">The State of External Retina Displays</a></li><li><a href=\"https://www.theverge.com/2021/12/21/22848957/lg-dualup-32-inch-4k-ultra-fine-monitors-announced-specs\">LG’s new 16:18 monitor looks like a multitasking powerhouse</a></li><li><a href=\"https://ssl.1242.com/aplform/form/aplform.php?fcode&#61;jpa2021_listener\">第3回 JAPAN PODCAST AWARDS 「リスナーズ・チョイス」 リスナー投票フォーム</a></li></ul></body></html>
        """)
        expected = """
        <html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-16le'><meta name='viewport' content='initial-scale=1.0' /><style type='text/css'>body { font-family: '-apple-system'; font-size: 16px; line-height: 22px; letter-spacing: -0.1px;background-color: transparent;color: #FFFFFF;margin: 8px 16px; word-wrap: break-word; } pre { white-space: pre-wrap; } a { color:#FFFFFF; font-family:'-apple-system'; text-decoration:underline; } h1,h2,h3,h4,h5,h6 { font-family: '-apple-system'; font-weight: normal; font-size: 16px; padding: 0; } img { width: auto !important; height: auto !important; max-width:100%; max-height: auto; padding-bottom: 10px; padding-top: 10px; display: block; } img[src*=\"coverart\" i] { display: none; } html { -webkit-text-size-adjust: none; } img[src*='feeds.feedburner.com'] { display: none; }</style></head><body><p>Kazuho Okui さんをゲストに迎えて、COVID-19, MacBook Pro, サバティカルなどについて話しました。</p>
        <h3>Show Notes</h3><ul><li><a href=\"https://sf.gov/data/covid-19-cases-and-deaths\">COVID-19 cases and deaths | San Francisco</a></li><li><a href=\"https://www.nbcnews.com/politics/white-house/biden-s-plan-free-home-covid-test-could-be-ineffective-n1285560\">Biden&#39;s plan for free at-home Covid test could be ineffective</a></li><li><a href=\"https://federalnewsnetwork.com/technology-main/2021/09/cbp-building-on-facial-recognition-successes-as-travelers-reap-benefits-of-expedited-process/\">CBP building on facial recognition successes as travelers reap benefits of expedited process</a></li><li><a href=\"https://developer.apple.com/documentation/authenticationservices/securing_logins_with_icloud_keychain_verification_codes\">Securing Logins with iCloud Keychain Verification Codes</a></li><li><a href=\"https://maestral.app/\">Maestral</a></li><li><a href=\"https://www.caldigit.com/thunderbolt-4-element-hub/\">Thunderbolt 4 | USB4 | Element Hub</a></li><li><a href=\"https://www.amazon.com/Anker-Charger-PowerPort-Charging-Station/dp/B09J1XTLJ6?&amp;linkCode&#61;ll1&amp;tag&#61;bulknewstypep-20\">Anker USB C Charger 120W, 547 Charger, PowerPort III 4-Port Charging Station</a></li><li><a href=\"https://www.caseyliss.com/2021/12/7/monitor-liss\">The State of External Retina Displays</a></li><li><a href=\"https://www.theverge.com/2021/12/21/22848957/lg-dualup-32-inch-4k-ultra-fine-monitors-announced-specs\">LG’s new 16:18 monitor looks like a multitasking powerhouse</a></li><li><a href=\"https://ssl.1242.com/aplform/form/aplform.php?fcode&#61;jpa2021_listener\">第3回 JAPAN PODCAST AWARDS 「リスナーズ・チョイス」 リスナー投票フォーム</a></li></ul></body></html>
        """
        XCTAssertEqual(actual, expected)

        // "Foundation - True Ventures" episode 8
        actual = ShowNotesFormatterUtils.convertToLinks(stringWithTimes: """
        <html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-16le'><meta name='viewport' content='initial-scale=1.0' /><style type='text/css'>body { font-family: '-apple-system'; font-size: 16px; line-height: 22px; letter-spacing: -0.1px;background-color: transparent;color: #FFFFFF;margin: 8px 16px; word-wrap: break-word; } pre { white-space: pre-wrap; } a { color:#FFFFFF; font-family:'-apple-system'; text-decoration:underline; } h1,h2,h3,h4,h5,h6 { font-family: '-apple-system'; font-weight: normal; font-size: 16px; padding: 0; } img { width: auto !important; height: auto !important; max-width:100%; max-height: auto; padding-bottom: 10px; padding-top: 10px; display: block; } img[src*=\"coverart\" i] { display: none; } html { -webkit-text-size-adjust: none; } img[src*='feeds.feedburner.com'] { display: none; }</style></head><body><p>Kevin and Oleg talk psychoacoustics, what it’s like to have created the first algorithm signed to a record deal, how in the world Oleg and his team turned a passion for ambient music into technology that improves human wellness, and more. </p><p>3:52 - Oleg speaks to the inception of the idea for an ambient sound generator</p><p>5:00 - Personalizing sounds for each moment of the day </p><p>8:21 - Oleg shares how he landed a spot in the Techstars Music Accelerator program </p><p>12:46 - Kevin asks how the Endel product works given its expansive vision  </p><p>20:48 - Creating a methodology that deciphers if an Endel user is in a “state of flow”</p><p>26:35 - Adapting environments to meet the moment  </p><p>27:32 - “They’re not designed to be consciously listened to,” shared Oleg</p><p>32:35 - The moment the press, and the world, noticed Endel</p><p>37:05 - Endel’s Apple Watch experience  </p><p>40:35 - Kevin inquires about how the platform creates elegant interconnectivity across devices </p><p>Learn more about Endel here: </p><p><a href=\"https://endel.io/\">https://endel.io/</a></p></body></html>
        """)
        expected = """
        <html><head><meta http-equiv='Content-Type' content='text/html; charset=utf-16le'><meta name='viewport' content='initial-scale=1.0' /><style type='text/css'>body { font-family: '-apple-system'; font-size: 16px; line-height: 22px; letter-spacing: -0.1px;background-color: transparent;color: #FFFFFF;margin: 8px 16px; word-wrap: break-word; } pre { white-space: pre-wrap; } a { color:#FFFFFF; font-family:'-apple-system'; text-decoration:underline; } h1,h2,h3,h4,h5,h6 { font-family: '-apple-system'; font-weight: normal; font-size: 16px; padding: 0; } img { width: auto !important; height: auto !important; max-width:100%; max-height: auto; padding-bottom: 10px; padding-top: 10px; display: block; } img[src*=\"coverart\" i] { display: none; } html { -webkit-text-size-adjust: none; } img[src*='feeds.feedburner.com'] { display: none; }</style></head><body><p>Kevin and Oleg talk psychoacoustics, what it’s like to have created the first algorithm signed to a record deal, how in the world Oleg and his team turned a passion for ambient music into technology that improves human wellness, and more. </p><p><a href=\"http://localhost/#playerJumpTo=3:52\">3:52</a> - Oleg speaks to the inception of the idea for an ambient sound generator</p><p><a href=\"http://localhost/#playerJumpTo=5:00\">5:00</a> - Personalizing sounds for each moment of the day </p><p><a href=\"http://localhost/#playerJumpTo=8:21\">8:21</a> - Oleg shares how he landed a spot in the Techstars Music Accelerator program </p><p><a href=\"http://localhost/#playerJumpTo=12:46\">12:46</a> - Kevin asks how the Endel product works given its expansive vision  </p><p><a href=\"http://localhost/#playerJumpTo=20:48\">20:48</a> - Creating a methodology that deciphers if an Endel user is in a “state of flow”</p><p><a href=\"http://localhost/#playerJumpTo=26:35\">26:35</a> - Adapting environments to meet the moment  </p><p><a href=\"http://localhost/#playerJumpTo=27:32\">27:32</a> - “They’re not designed to be consciously listened to,” shared Oleg</p><p><a href=\"http://localhost/#playerJumpTo=32:35\">32:35</a> - The moment the press, and the world, noticed Endel</p><p><a href=\"http://localhost/#playerJumpTo=37:05\">37:05</a> - Endel’s Apple Watch experience  </p><p><a href=\"http://localhost/#playerJumpTo=40:35\">40:35</a> - Kevin inquires about how the platform creates elegant interconnectivity across devices </p><p>Learn more about Endel here: </p><p><a href=\"https://endel.io/\">https://endel.io/</a></p></body></html>
        """
        XCTAssertEqual(actual, expected)
    }
}
