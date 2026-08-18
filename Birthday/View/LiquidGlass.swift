import SwiftUI

// MARK: - Liquid Glass helpers (iOS 26+)

enum LiquidGlass {
    static let cardCornerRadius: CGFloat = 24
    static let fieldCornerRadius: CGFloat = 12
}

extension View {
    /// Applies Apple's Liquid Glass material in a rounded rect, with a material fallback before iOS 26.
    @ViewBuilder
    func liquidGlassCard(
        cornerRadius: CGFloat = LiquidGlass.cardCornerRadius,
        interactive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            let glass: Glass = interactive ? .regular.interactive() : .regular
            glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
        } else {
            background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(AppTheme.text.opacity(0.15), lineWidth: 1)
                )
        }
    }

    /// Primary action button — glass prominent on iOS 26, solid fill fallback otherwise.
    @ViewBuilder
    func primaryGlassButton() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(LegacyPrimaryButtonStyle())
        }
    }

    /// Secondary / toolbar action — glass on iOS 26.
    @ViewBuilder
    func secondaryGlassButton() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(LegacyPrimaryButtonStyle())
        }
    }

    /// Browse/segment control style — glass prominent when selected.
    @ViewBuilder
    func browseGlassButtonStyle(isProminent: Bool) -> some View {
        if #available(iOS 26.0, *) {
            if isProminent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else {
            buttonStyle(LegacyPrimaryButtonStyle())
        }
    }

    /// Circular icon action — official glass, no solid fill.
    @ViewBuilder
    func glassCircleButton() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glass)
                .buttonBorderShape(.circle)
        } else {
            buttonStyle(LegacyCircleButtonStyle(color: AppTheme.text.opacity(0.15)))
        }
    }
}

private struct LegacyPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.blue.opacity(configuration.isPressed ? 0.85 : 1))
            .foregroundStyle(.white) // always on a blue fill, in both schemes
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct LegacyCircleButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(color.opacity(configuration.isPressed ? 0.85 : 1))
            .foregroundStyle(AppTheme.text)
            .clipShape(Circle())
    }
}

/// Wraps content in a padded glass card shell used across contact rows and panels.
struct LiquidGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = LiquidGlass.cardCornerRadius
    var interactive: Bool = false
    var padding: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .liquidGlassCard(cornerRadius: cornerRadius, interactive: interactive)
    }
}

/// Standard contact row: content + padding + liquid glass (use inside button labels).
struct ContactGlassRow<Content: View>: View {
    var interactive: Bool = true
    var padding: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .liquidGlassCard(cornerRadius: LiquidGlass.cardCornerRadius, interactive: interactive)
    }
}

/// Compact chevron back control — matches NavigationStack liquid glass back on iOS 26.
struct LiquidGlassBackButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
        }
        .accessibilityLabel("Back")
    }
}

extension View {
    /// Large, centered navigation title. Inline system titles are centered; a custom
    /// principal view keeps the type large (large titles are leading-aligned on iOS).
    func centeredNavigationTitle(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                        .accessibilityHidden(true)
                }
            }
            .toolbarBackground(AppTheme.background, for: .navigationBar)
    }

    /// Large navigation title matching pre-redesign tab headers (centered).
    func largeNavigationTitle(_ title: String) -> some View {
        centeredNavigationTitle(title)
    }

    /// Liquid glass back affordance in the navigation bar leading slot.
    func liquidGlassBackToolbar(action: @escaping () -> Void) -> some View {
        toolbar {
            ToolbarItem(placement: .topBarLeading) {
                LiquidGlassBackButton(action: action)
            }
        }
    }
}
