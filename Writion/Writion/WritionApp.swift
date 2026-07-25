import Darwin
import SwiftUI

@main
struct WritionApp: App {
    @AppStorage("hasAcceptedNWsLicense") private var hasAcceptedNWsLicense = false

    var body: some Scene {
        WindowGroup {
            RootContainerView(hasAcceptedNWsLicense: $hasAcceptedNWsLicense)
        }
    }
}

private struct RootContainerView: View {
    @Binding var hasAcceptedNWsLicense: Bool
    @State private var hasSeenFeatureHighlights = false

    var body: some View {
        #if os(iOS)
        Group {
            if hasAcceptedNWsLicense {
                WritionHomeView(onResetLicense: {
                    hasAcceptedNWsLicense = false
                    hasSeenFeatureHighlights = false
                })
                .transition(.writionAppearFromLargeFade)
            } else if hasSeenFeatureHighlights {
                CreatorFeaturesView(
                    onContinue: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            hasAcceptedNWsLicense = true
                        }
                    }
                )
                .transition(.featureStageTransition)
                .statusBarHidden(false)
            } else {
                LicenseAgreementView(
                    onAgree: {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            hasSeenFeatureHighlights = true
                        }
                    },
                    onClose: {
                        exit(0)
                    }
                )
                .transition(.licenseStageTransition)
                .statusBarHidden(true)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasSeenFeatureHighlights)
        .animation(.easeInOut(duration: 0.35), value: hasAcceptedNWsLicense)
        #else
        WritionHomeView(onResetLicense: { hasAcceptedNWsLicense = false })
            .sheet(isPresented: Binding(get: { !hasAcceptedNWsLicense }, set: { _ in })) {
                LicenseAgreementView(
                    onAgree: {
                        hasAcceptedNWsLicense = true
                    },
                    onClose: {
                        exit(0)
                    }
                )
                .interactiveDismissDisabled(true)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        #endif
    }
}

#if os(iOS)
private extension AnyTransition {
    static var writionAppearFromLargeFade: AnyTransition {
        .scale(scale: 1.08).combined(with: .opacity)
    }

    static var writionDisappearToLargeFade: AnyTransition {
        .scale(scale: 1.12).combined(with: .opacity)
    }

    static var featureAppearFromLargeFade: AnyTransition {
        .scale(scale: 1.08).combined(with: .opacity)
    }

    static var licenseDisappearToBottom: AnyTransition {
        .move(edge: .bottom)
    }

    static var licenseStageTransition: AnyTransition {
        .asymmetric(
            insertion: .identity,
            removal: .licenseDisappearToBottom
        )
    }

    static var featureStageTransition: AnyTransition {
        .asymmetric(
            insertion: .featureAppearFromLargeFade,
            removal: .writionDisappearToLargeFade
        )
    }
}
#endif

private struct WritionHomeView: View {
    let onResetLicense: () -> Void

    @State private var draftText = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.92, blue: 0.88),
                    Color(red: 0.89, green: 0.84, blue: 0.78),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Text("Writion")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)

                Button("test", action: onResetLicense)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .foregroundStyle(.white)
                    .background(Color(red: 0.40, green: 0.27, blue: 0.16), in: Capsule())
                    .modifier(WritionGlassSurface(cornerRadius: 27))

                TextField("输入一些内容...", text: $draftText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .frame(minHeight: 120, alignment: .topLeading)
                    .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .modifier(WritionGlassSurface(cornerRadius: 24))
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 560)
        }
    }
}

private struct WritionGlassSurface: ViewModifier {
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}
