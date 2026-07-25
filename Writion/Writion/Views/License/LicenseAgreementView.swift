import SwiftUI
#if os(iOS)
//import UIKit
#endif

/// A first-launch license agreement gate styled like Apple's onboarding prompt.
struct LicenseAgreementView: View {
    @Environment(\.colorScheme) private var colorScheme

    let onAgree: () -> Void
    let onClose: () -> Void

    private let themeColor = Color(red: 0.60, green: 0.43, blue: 0.26)
    // 调整灰色说明文字与“进一步了解...”之间的行间距（当前先增加 2）。
    private let infoTextToLearnMoreSpacing: CGFloat = 6
    // iPad 许可页内容最大宽度（当前 680，可按设计调整，避免在大屏无限拉伸）。
    private let iPadContentMaxWidth: CGFloat = 680

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 14) {
                appIconView
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 1) {
                    Text("欢迎使用 Writion 创作")
                        .font(.system(size: 22, weight: .bold))
                        .lineLimit(2)

                    Text("你可以轻点进一步了解，查看“Writion 创作”如何使用你的数据，或者继续以开始使用。")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, infoTextToLearnMoreSpacing)

                if let detailsURL = URL(string: "https://blog.nws.us.kg") {
                    Link(destination: detailsURL) {
                        HStack(alignment: .center, spacing: 4) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 21, weight: .regular))
                            Text("进一步了解...")
                                .font(.system(size: 16, weight: .regular))
                        }
                    }
                    .tint(themeColor)
                }
            }
            .padding(.horizontal, 36)
            .padding(.top, -120)
            .frame(maxWidth: contentMaxWidth, alignment: .leading)

            Spacer(minLength: 20)

            VStack(spacing: 12) {
                Button(action: onAgree) {
                    Text("接受并继续")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(themeColor.opacity(0.95), in: Capsule())
                        .glassEffect(.regular, in: .rect(cornerRadius: 27))
                        .shadow(color: themeColor.opacity(0.24), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                Button(action: onClose) {
                    Text("关闭 Writion 创作")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .glassEffect(.regular, in: .rect(cornerRadius: 27))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 2)
            .frame(maxWidth: contentMaxWidth)
        }
        .frame(maxWidth: .infinity)
        .background(backgroundStyle)
    }

    @ViewBuilder
    private var appIconView: some View {
        #if os(iOS)
        if let iconImage = UIApplication.shared.primaryAppIconImage {
            Image(uiImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 86, height: 86)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.top, -111)
        } else {
            fallbackIcon
        }
        #else
        fallbackIcon
        #endif
    }

    private var fallbackIcon: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [themeColor, themeColor.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 88, height: 88)
            .overlay {
                Image(systemName: "text.book.closed.fill")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
            }
            .padding(.top, -160)
    }

    private var backgroundStyle: some ShapeStyle {
        colorScheme == .dark ? .black : .white
    }

    private var contentMaxWidth: CGFloat? {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .pad ? iPadContentMaxWidth : nil
        #else
        nil
        #endif
    }
}

#if os(iOS)
struct CreatorFeaturesView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onContinue: () -> Void

    private let themeColor = Color(red: 0.60, green: 0.43, blue: 0.26)
    // 调整“nhx9605 Workspace 出品。”灰色说明文字下方与功能列表之间的行间距（当前先设置为 2）。
    private let introToFeatureSpacing: CGFloat = 30
    // 调整四个功能图标的缩进（当前先设置为 1）。
    private let featureIconLeadingInset: CGFloat = 10
    // 调整功能标题与功能介绍之间的行间距（当前先设置为 2）。
    private let featureTitleDescriptionSpacing: CGFloat = 2
    // 调整每个功能板块（标题+图标+文字描述）之间的行间距（当前先设置为 2，便于后续调整）。
    private let featureBlockSpacing: CGFloat = 20
    // 调整“完整功能列表”与上一行内容之间的行间距（当前先设置为 2）。
    private let fullFeatureListTopSpacing: CGFloat = 40
    // iPad 功能许可页内容最大宽度（当前 760，可按设计调整，避免在大屏无限拉伸）。
    private let iPadContentMaxWidth: CGFloat = 660

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Writion 创作的主要功能")
                        .font(.system(size: 22, weight: .bold))
                        .padding(.top, 110)

                    Text("免费的，使用 MIT 协议开源的，原生 Swift 语言编写的，轻量化创作 App。NovaWise Syndicate 出品。")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, introToFeatureSpacing)

                    VStack(alignment: .leading, spacing: featureBlockSpacing) {
                        featureRow(icon: "lock.document", title: "文档加密", description: "通过端对端加密保障隐私安全。")
                        featureRow(icon: "externaldrive.badge.icloud", title: "通过iCloud同步", description: "文档同步上传 iCloud，你的创作稳定有保障。")
                        featureRow(icon: "square.and.arrow.up.on.square", title: "快速分享", description: "快速导出为 *.epub 或 *.md 供他人导入使用。")
                        featureRow(icon: "character.text.justify", title: "友好界面", description: "拒绝繁琐，使用 Writion 创作让你感到编辑 Markdown 和使用 Word 或 Pages 文稿一般容易。")
                    }

                    if let fullFeatureListURL = URL(string: "https://blog.nws.us.kg") {
                        Link(destination: fullFeatureListURL) {
                            Text("完整功能列表  ›")
                                .font(.system(size: 17, weight: .regular))
                        }
                        .tint(themeColor)
                        .padding(.top, fullFeatureListTopSpacing)
                    }
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 28)
                .frame(maxWidth: contentMaxWidth, alignment: .leading)
            }

            VStack(spacing: 14) {
                Text(.init(String(localized: "轻点“继续”即表示你同意《[Writion 创作软件许可协议](https://raw.githubusercontent.com/nhx100218/Writion-iOS/main/LICENSE)》的条款。")))
                    .tint(themeColor)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 10, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onContinue) {
                    Text("继续")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(themeColor.opacity(0.95), in: Capsule())
                        .glassEffect(.regular, in: .rect(cornerRadius: 27))
                        .shadow(color: themeColor.opacity(0.24), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 34)
            .padding(.top, 12)
            .padding(.bottom, 2)
            .frame(maxWidth: contentMaxWidth)
        }
        .frame(maxWidth: .infinity)
        .background(backgroundStyle)
    }

    @ViewBuilder
    private func featureRow(icon: String, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(themeColor)
                .frame(width: 52, height: 52, alignment: .top)
                .padding(.leading, featureIconLeadingInset)

            VStack(alignment: .leading, spacing: featureTitleDescriptionSpacing) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Text(description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    private var backgroundStyle: some ShapeStyle {
        colorScheme == .dark ? .black : .white
    }

    private var contentMaxWidth: CGFloat? {
        UIDevice.current.userInterfaceIdiom == .pad ? iPadContentMaxWidth : nil
    }
}
#endif

#if os(iOS)
private extension UIApplication {
    var primaryAppIconImage: UIImage? {
        guard
            let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primary["CFBundleIconFiles"] as? [String],
            let iconName = iconFiles.last,
            let image = UIImage(named: iconName)
        else {
            return nil
        }

        return image
    }
}
#endif
