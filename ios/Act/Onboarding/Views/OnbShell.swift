import SwiftUI

/// Shared skeleton for every Onb* screen, mirroring the design JSX `OnbShell`:
/// black surface, one hero word ending in a period, optional sub-line,
/// scrollable body content, optional secondary links, and the single sticky
/// lime CTA. Per design.v3 §Hard lines the CTA is always enabled and "Back"
/// is a mono text link above it — never a second button style.
struct OnbShell<Content: View, Secondary: View>: View {
    let hero: String
    var heroSize: ACTTokens.TypeScale = .s84
    var heroKerning: CGFloat = -3.5
    var sub: String?
    let ctaTitle: String
    var showsBackLink = false
    var onBack: () -> Void = {}
    var onCTA: () -> Void = {}
    @ViewBuilder var content: () -> Content
    @ViewBuilder var secondary: () -> Secondary

    var body: some View {
        ZStack {
            ACTTokens.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(hero)
                            .font(ACTTokens.TYPE.display(heroSize, weight: .heavy))
                            .kerning(heroKerning)
                            .foregroundStyle(ACTTokens.text)
                            .padding(.top, 16)
                        if let sub {
                            Text(sub)
                                .font(ACTTokens.TYPE.text(.s20, weight: .medium))
                                .foregroundStyle(ACTTokens.textDim)
                                .padding(.top, 12)
                        }
                        content()
                            .padding(.top, 32)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
                secondary()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                if showsBackLink {
                    Button(action: onBack) {
                        Text("← Back")
                            .font(ACTTokens.TYPE.mono(.s13))
                            .foregroundStyle(ACTTokens.textDim)
                    }
                    .padding(.bottom, 12)
                }
                Button(action: onCTA) {
                    Text(ctaTitle)
                        .font(ACTTokens.TYPE.text(.s18, weight: .bold))
                        .foregroundStyle(ACTTokens.limeText)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(ACTTokens.lime, in: RoundedRectangle(cornerRadius: 18))
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
        }
        .preferredColorScheme(.dark)
    }
}

extension OnbShell where Secondary == EmptyView {
    init(
        hero: String,
        heroSize: ACTTokens.TypeScale = .s84,
        heroKerning: CGFloat = -3.5,
        sub: String? = nil,
        ctaTitle: String,
        showsBackLink: Bool = false,
        onBack: @escaping () -> Void = {},
        onCTA: @escaping () -> Void = {},
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            hero: hero,
            heroSize: heroSize,
            heroKerning: heroKerning,
            sub: sub,
            ctaTitle: ctaTitle,
            showsBackLink: showsBackLink,
            onBack: onBack,
            onCTA: onCTA,
            content: content,
            secondary: { EmptyView() }
        )
    }
}
