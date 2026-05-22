import SwiftUI
import UIKit
import XCTest
@testable import Act

final class ACTTokensTests: XCTestCase {
    func testAccentColorsAreDistinct() {
        let accents: [(name: String, color: Color)] = [
            ("lime", ACTTokens.lime),
            ("warn", ACTTokens.warn),
            ("red", ACTTokens.red)
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
