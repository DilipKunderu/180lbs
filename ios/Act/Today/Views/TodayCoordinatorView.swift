import SwiftUI

/// Dumb switch over `TodayCoordinatorModel.state`.
///
/// Routes `.weighIn` to the built `CmdWeighIn` screen. Every other state
/// returns a small design-compliant placeholder ("not yet built") — dark
/// `ACTTokens.bg` background with a single mono label — so the app never
/// crashes when the coordinator lands on a state whose screen hasn't shipped.
///
/// Lifecycle: `.onAppear` refreshes facts and kicks off the async body-mass
/// read. The `.task` modifier re-runs refresh on each SwiftUI task lifetime so
/// facts stay current across scene activations.
struct TodayCoordinatorView: View {
    let model: TodayCoordinatorModel

    var body: some View {
        ZStack {
            ACTTokens.bg.ignoresSafeArea()
            switch model.state {
            case .weighIn:
                CmdWeighIn(
                    prefilledWeightLb: model.prefilledWeightLb,
                    onGood: { lb in try? model.logWeighIn(lb: lb) }
                )
            default:
                notYetBuiltPlaceholder
            }
        }
        .onAppear {
            model.refresh()
            model.loadBodyMass()
        }
    }

    // MARK: - Placeholder

    private var notYetBuiltPlaceholder: some View {
        Text("—")
            .font(ACTTokens.TYPE.mono(.s28))
            .foregroundStyle(ACTTokens.textMute)
    }
}
