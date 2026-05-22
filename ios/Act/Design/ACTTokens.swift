import SwiftUI

/// Namespace for the ACT design-system tokens.
enum ACTTokens {
    // MARK: - Surfaces

    static let bg = sRGB(0, 0, 0)
    static let surface = sRGB(10, 10, 10)
    static let surface2 = sRGB(20, 20, 20)
    static let surface3 = sRGB(28, 28, 30)
    static let hairline = sRGB(255, 255, 255, opacity: 0.08)
    static let hairline2 = sRGB(255, 255, 255, opacity: 0.14)

    // MARK: - Text

    static let text = sRGB(255, 255, 255)
    static let textDim = sRGB(255, 255, 255, opacity: 0.55)
    static let textMute = sRGB(255, 255, 255, opacity: 0.32)
    static let textFaint = sRGB(255, 255, 255, opacity: 0.18)

    // MARK: - Accents

    // OKLCH values are precomputed into gamma-encoded Display P3 components
    // using the OKLab matrices from https://bottosson.github.io/posts/oklab/
    // followed by the CSS Color 4 XYZ D65 -> Display P3 conversion matrix.
    static let lime = displayP3(red: 0.740269395, green: 0.927940411, blue: 0.469701247)
    static let limeDim = displayP3(red: 0.740269395, green: 0.927940411, blue: 0.469701247, opacity: 0.18)
    static let limeText = sRGB(0, 0, 0)
    static let warn = displayP3(red: 0.950176229, green: 0.628477570, blue: 0.313815094)
    static let ok = displayP3(red: 0.502562348, green: 0.811646956, blue: 0.583448795)
    static let red = displayP3(red: 0.941163343, green: 0.357008882, blue: 0.332678471)

    enum TypeScale: Int, CaseIterable {
        case s96 = 96
        case s84 = 84
        case s72 = 72
        case s56 = 56
        case s44 = 44
        case s36 = 36
        case s28 = 28
        case s24 = 24
        case s22 = 22
        case s20 = 20
        case s18 = 18
        case s16 = 16
        case s14 = 14
        case s13 = 13
        case s12 = 12
        case s11 = 11

        var points: CGFloat {
            CGFloat(rawValue)
        }
    }

    enum TYPE {
        static func display(_ size: TypeScale, weight: Font.Weight = .regular) -> Font {
            Font.custom("SF Pro Display", size: size.points).weight(weight)
        }

        static func text(_ size: TypeScale, weight: Font.Weight = .regular) -> Font {
            Font.custom("SF Pro Text", size: size.points).weight(weight)
        }

        static func mono(_ size: TypeScale, weight: Font.Weight = .regular) -> Font {
            Font.custom("SF Mono", size: size.points).weight(weight)
        }
    }

    private static func sRGB(_ red: Double, _ green: Double, _ blue: Double, opacity: Double = 1) -> Color {
        Color(.sRGB, red: red / 255, green: green / 255, blue: blue / 255, opacity: opacity)
    }

    private static func displayP3(red: Double, green: Double, blue: Double, opacity: Double = 1) -> Color {
        Color(.displayP3, red: red, green: green, blue: blue, opacity: opacity)
    }
}
