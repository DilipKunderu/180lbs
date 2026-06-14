import SwiftUI

/// Manual numeric weight-entry surface shown when no smart-scale value is
/// available (HealthKit denied, no prior reading, or stale).
///
/// Design.v5 §Failure modes wording: "STALE · TAP TO ENTER".
/// Visual system: `ACTTokens.bg` background, SF Mono for the weight value
/// (`ACTTokens.TYPE.mono`), mono section label for the stale tag, single lime
/// sticky CTA 56pt height. No cards, no raw hex literals.
///
/// This view is a pure renderer: it owns no digit-accumulation state machine.
/// The caller supplies the current display value (`weightDisplay`), digit and
/// delete handlers, and the confirm CTA handler. Keeping the digit-accumulation
/// logic in the parent means `CmdWeightPad` tests snapshot layout only, while
/// the digit logic is covered by its own unit tests at the parent layer.
struct CmdWeightPad: View {

    // MARK: - Input

    /// Formatted weight string rendered in the large mono display (e.g. "185.0").
    let weightDisplay: String

    /// Called when the user taps a keypad digit (0–9) or the decimal point.
    var onDigit: (String) -> Void = { _ in }

    /// Called when the user taps the backspace key.
    var onDelete: () -> Void = {}

    /// Called when the user taps the lime "Good." CTA to confirm the entry.
    var onCTA: () -> Void = {}

    // MARK: - Body

    var body: some View {
        ZStack {
            ACTTokens.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                weightDisplayArea
                Spacer(minLength: 0)
                keypad
                ctaButton
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
            }
            .padding(.top, 48)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sub-views

    private var weightDisplayArea: some View {
        VStack(alignment: .center, spacing: 16) {
            staleTag
            weightValue
            unitLabel
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var staleTag: some View {
        Text("STALE · TAP TO ENTER")
            .font(ACTTokens.TYPE.mono(.s11))
            .kerning(1.2)
            .foregroundStyle(ACTTokens.textMute)
    }

    private var weightValue: some View {
        Text(weightDisplay.isEmpty ? "—" : weightDisplay)
            .font(ACTTokens.TYPE.mono(.s84, weight: .heavy))
            .kerning(-3.5)
            .foregroundStyle(weightDisplay.isEmpty ? ACTTokens.textFaint : ACTTokens.text)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .contentTransition(.numericText())
            .animation(.snappy, value: weightDisplay)
    }

    private var unitLabel: some View {
        Text("LBS")
            .font(ACTTokens.TYPE.mono(.s13))
            .kerning(1.2)
            .foregroundStyle(ACTTokens.textDim)
    }

    private var keypad: some View {
        VStack(spacing: 0) {
            keypadRow(keys: ["1", "2", "3"])
            keypadRow(keys: ["4", "5", "6"])
            keypadRow(keys: ["7", "8", "9"])
            keypadBottomRow
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }

    private var keypadBottomRow: some View {
        HStack(spacing: 0) {
            keypadKey(".")
            keypadKey("0")
            deleteKey
        }
    }

    private func keypadRow(keys: [String]) -> some View {
        HStack(spacing: 0) {
            ForEach(keys, id: \.self) { key in
                keypadKey(key)
            }
        }
    }

    private func keypadKey(_ label: String) -> some View {
        Button {
            onDigit(label)
        } label: {
            Text(label)
                .font(ACTTokens.TYPE.mono(.s28, weight: .medium))
                .foregroundStyle(ACTTokens.text)
                .frame(maxWidth: .infinity, minHeight: 68)
        }
    }

    private var deleteKey: some View {
        Button(action: onDelete) {
            Image(systemName: "delete.left")
                .font(ACTTokens.TYPE.mono(.s22))
                .foregroundStyle(ACTTokens.textDim)
                .frame(maxWidth: .infinity, minHeight: 68)
        }
    }

    private var ctaButton: some View {
        Button(action: onCTA) {
            Text("Good.")
                .font(ACTTokens.TYPE.text(.s18, weight: .bold))
                .foregroundStyle(ACTTokens.limeText)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(ACTTokens.lime, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

// MARK: - Preview

#Preview {
    CmdWeightPad(weightDisplay: "185.0")
}
