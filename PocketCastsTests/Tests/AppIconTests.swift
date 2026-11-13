@testable import podcasts
import XCTest

final class AppIconTests: XCTestCase {
    func testEveryIconIsDeclaredAsAnAlternateIconWithAssetCatalogArtwork() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "Info", withExtension: "plist"))
        let info = try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil) as? [String: Any])

        for key in ["CFBundleIcons", "CFBundleIcons~ipad"] {
            let icons = try XCTUnwrap(info[key] as? [String: Any], key)
            let primary = try XCTUnwrap(icons["CFBundlePrimaryIcon"] as? [String: Any], key)
            XCTAssertEqual(primary["CFBundleIconName"] as? String, "AppIcon", key)

            let alternates = try XCTUnwrap(icons["CFBundleAlternateIcons"] as? [String: [String: Any]], key)
            for icon in IconType.allCases {
                let name = try XCTUnwrap(icon.iconName)
                XCTAssertEqual(alternates[name]?["CFBundleIconName"] as? String, name, "\(key) is missing \(name)")
            }
        }
    }
}
