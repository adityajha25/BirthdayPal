import SwiftUI
import UIKit

/// App palette. Every color is trait-based, so it follows the device's
/// light/dark setting automatically: near-black in dark, cream in light.
enum AppTheme {
    /// Page background — black in dark mode, very light cream in light mode.
    static let background = dynamic(
        light: UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1),
        dark: UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1)
    )

    /// Raised surface behind capsules / confirmations.
    static let surface = dynamic(
        light: UIColor(red: 0.93, green: 0.90, blue: 0.84, alpha: 1),
        dark: UIColor(red: 0.12, green: 0.16, blue: 0.35, alpha: 1)
    )

    /// Primary text + icon color. Use `.opacity(_:)` for the muted variants.
    static let text = dynamic(
        light: UIColor(red: 0.14, green: 0.12, blue: 0.09, alpha: 1),
        dark: UIColor.white
    )

    /// Accent for toggles, icons and spinners. Cyan is illegible on cream,
    /// so light mode drops to a deep teal at the same hue.
    static let accent = dynamic(
        light: UIColor(red: 0.00, green: 0.42, blue: 0.50, alpha: 1),
        dark: UIColor.systemCyan
    )

    /// Celebration highlight ("Today!", confetti). Yellow washes out on cream.
    static let celebration = dynamic(
        light: UIColor(red: 0.80, green: 0.52, blue: 0.02, alpha: 1),
        dark: UIColor.systemYellow
    )

    /// Fill behind avatar initials and month/day badges.
    static let badgeFill = dynamic(
        light: UIColor(red: 0.86, green: 0.83, blue: 0.75, alpha: 1),
        dark: UIColor(red: 0.15, green: 0.20, blue: 0.40, alpha: 1)
    )

    /// UIKit counterpart of `accent`, for the calendar representable.
    static let accentUIColor = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.systemCyan
            : UIColor(red: 0.00, green: 0.42, blue: 0.50, alpha: 1)
    }

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}
