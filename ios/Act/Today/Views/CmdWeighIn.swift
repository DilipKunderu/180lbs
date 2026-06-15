import SwiftUI

/// Today's weigh-in screen.
///
/// **Pure renderer** — owns no coordinator model directly; callers inject
/// `prefilledWeightLb` (from HealthKit / cache) and an `onGood` closure so
/// the view is snapshotable without a live `TodayCoordinatorModel`.
///
/// - When `prefilledWeightLb != nil`: renders the "Weigh." hero using
///   `ACTTokens.TYPE.display`, the value as large SF Mono with "LBS", and
///   the single lime "Good." sticky CTA that calls `onGood(value)`.
/// - When `prefilledWeightLb == nil` (scale offline / HealthKit denied):
///   embeds `CmdWeightPad` as the manual-entry fallback, forwarding digit,
///   delete, and confirm handlers through to the pad.
///
/// Design system: `ACTTokens` only — no raw hex; SF Mono for numerics;
/// one hero word ending in a period; single lime sticky CTA. Mirrors
/// `OnbShell` hero+CTA layout for visual consistency.
struct CmdWeighIn: View {

    // MARK: - Input

    /// Pre-filled weight from HealthKit or cache. `nil` → manual-pad fallback.
    let prefilledWeightLb: Double?

    /// Called when the user confirms a weigh-in. The `WeightLogSource` records
    /// provenance: `.healthkit` from the pre-filled hero CTA, `.manualPad` from
    /// the manual-entry pad.
    var onGood: (Double, WeightLogSource) -> Void = { _, _ in }

    // MARK: - Manual-pad state (used only when prefilledWeightLb == nil)

    /// Accumulated digit string for the manual pad, e.g. "1850" → "185.0".
    @State private var padDigits: String = ""

    // MARK: - Body

    var body: some View {
        if let weight = prefilledWeightLb {
            prefilledView(weight: weight)
        } else {
            manualPadView
        }
    }

    // MARK: - Pre-filled state

    private func prefilledView(weight: Double) -> some View {
        OnbShell(
            hero: "Weigh.",
            ctaTitle: "Good.",
            onCTA: { onGood(weight, .healthkit) },
            content: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedWeight(weight))
                        .font(ACTTokens.TYPE.mono(.s84, weight: .heavy))
                        .kerning(-3.5)
                        .foregroundStyle(ACTTokens.text)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("LBS")
                        .font(ACTTokens.TYPE.mono(.s13))
                        .kerning(1.2)
                        .foregroundStyle(ACTTokens.textDim)
                }
            }
        )
    }

    // MARK: - Manual-pad fallback

    private var manualPadView: some View {
        CmdWeightPad(
            weightDisplay: padDisplayString,
            onDigit: { digit in
                padDigits += digit
            },
            onDelete: {
                if !padDigits.isEmpty {
                    padDigits.removeLast()
                }
            },
            onCTA: {
                if let value = Double(padDisplayString) {
                    onGood(value, .manualPad)
                }
            }
        )
    }

    // MARK: - Helpers

    /// "3084" → "308.4", "" → "". Mirrors the digit-accumulation pattern
    /// expected by `CmdWeightPad.weightDisplay`.
    private var padDisplayString: String {
        guard !padDigits.isEmpty else { return "" }
        // Insert decimal before last digit: "3084" → "308.4"
        if padDigits.count > 1 {
            let intPart = String(padDigits.prefix(padDigits.count - 1))
            let decPart = String(padDigits.suffix(1))
            return "\(intPart).\(decPart)"
        }
        return "0.\(padDigits)"
    }

    private func formattedWeight(_ lb: Double) -> String {
        String(format: "%.1f", lb)
    }
}

// MARK: - Preview

#Preview("Pre-filled") {
    CmdWeighIn(prefilledWeightLb: 308.4, onGood: { _, _ in })
}

#Preview("Manual pad") {
    CmdWeighIn(prefilledWeightLb: nil, onGood: { _, _ in })
}
