import SwiftUI
import UIKit
import XCTest
@testable import Act

final class ACTTokensTests: XCTestCase {
    func testAccentColorsAreDistinct() {
        let accents: [(name: String, color: Color)] = [
            ("lime", ACTTokens.lime),
            ("amber", ACTTokens.amber),
            ("lava", ACTTokens.lava)
        ]

        for i in 0..<accents.count {
            for j in (i + 1)..<accents.count {
                let lhs = UIColor(accents[i].color).cgColor.components ?? []
                let rhs = UIColor(accents[j].color).cgColor.components ?? []
                XCTAssertNotEqual(
                    lhs,
                    rhs,
                    "\(accents[i].name) and \(accents[j].name) share RGB components - copy-paste error?"
                )
            }
        }
    }

    /// GAP-TOKEN-1: lock each accent to its design.v5 OKLCH-derived Display P3
    /// components, so a wrong/copy-pasted value is caught (the distinctness test
    /// alone would pass even if all three were wrong-but-different).
    func test_accentTokens_matchDesignV5DisplayP3Components() throws {
        try assertP3(ACTTokens.lime, 0.740269395, 0.927940411, 0.469701247, name: "lime")
        try assertP3(ACTTokens.amber, 0.950176229, 0.628477570, 0.313815094, name: "amber")
        try assertP3(ACTTokens.lava, 0.941163343, 0.357008882, 0.332678471, name: "lava")
    }

    private func assertP3(
        _ color: Color, _ red: Double, _ green: Double, _ blue: Double, name: String
    ) throws {
        let p3 = try XCTUnwrap(CGColorSpace(name: CGColorSpace.displayP3))
        let converted = try XCTUnwrap(
            UIColor(color).cgColor.converted(to: p3, intent: .defaultIntent, options: nil)
        )
        let c = try XCTUnwrap(converted.components)
        XCTAssertEqual(Double(c[0]), red, accuracy: 0.005, "\(name) red")
        XCTAssertEqual(Double(c[1]), green, accuracy: 0.005, "\(name) green")
        XCTAssertEqual(Double(c[2]), blue, accuracy: 0.005, "\(name) blue")
    }

    func testTypeScaleContainsAllDesignSizes() {
        XCTAssertEqual(
            ACTTokens.TypeScale.allCases.map(\.rawValue),
            [
                120, 96, 84, 72, 56, 44, 40, 36, 32, 28,
                24, 22, 20, 18, 16, 14, 13, 12, 11, 9
            ]
        )
    }

    func testFontHelpersAcceptEveryDesignSize() {
        for size in ACTTokens.TypeScale.allCases {
            _ = ACTTokens.TYPE.display(size)
            _ = ACTTokens.TYPE.text(size)
            _ = ACTTokens.TYPE.mono(size)
        }
    }
}
