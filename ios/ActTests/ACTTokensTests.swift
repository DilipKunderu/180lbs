import SwiftUI
import UIKit
import XCTest
@testable import Act

final class ACTTokensTests: XCTestCase {
    func testColorTokensResolveToVisibleColors() {
        let colors: [Color] = [
            ACTTokens.bg,
            ACTTokens.surface,
            ACTTokens.surface2,
            ACTTokens.surface3,
            ACTTokens.hairline,
            ACTTokens.hairline2,
            ACTTokens.text,
            ACTTokens.textDim,
            ACTTokens.textMute,
            ACTTokens.textFaint,
            ACTTokens.lime,
            ACTTokens.limeDim,
            ACTTokens.limeText,
            ACTTokens.warn,
            ACTTokens.ok,
            ACTTokens.red
        ]

        XCTAssertEqual(colors.count, 16)
        for color in colors {
            XCTAssertGreaterThan(UIColor(color).cgColor.alpha, 0)
        }
    }

    func testTypeScaleContainsAllDesignSizes() {
        XCTAssertEqual(
            ACTTokens.TypeScale.allCases.map(\.rawValue),
            [96, 84, 72, 56, 44, 36, 28, 24, 22, 20, 18, 16, 14, 13, 12, 11]
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
