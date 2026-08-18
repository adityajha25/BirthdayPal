import SwiftUI
import UIKit

/// Circular contact thumbnail with initials / symbol fallback. Decodes thumbnail off-screen-size only.
struct ContactPhotoView: View {
    let name: String
    let thumbnailData: Data?
    var size: CGFloat = 48
    var showsStroke: Bool = true

    var body: some View {
        Group {
            if let thumbnailData, let image = UIImage(data: thumbnailData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle()
                        .fill(AppTheme.badgeFill.opacity(0.9))
                    if let initials = Self.initials(from: name) {
                        Text(initials)
                            .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.text.opacity(0.92))
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.42, weight: .medium))
                            .foregroundStyle(AppTheme.text.opacity(0.75))
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            if showsStroke {
                Circle()
                    .stroke(AppTheme.text.opacity(0.28), lineWidth: 1.5)
            }
        }
        .accessibilityHidden(true)
    }

    /// Up to two initials. `nil` when the name is missing / placeholder so we show a person symbol instead.
    static func initials(from name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.caseInsensitiveCompare("No Name") != .orderedSame else {
            return nil
        }
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
        let letters = parts.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
        guard !letters.isEmpty else { return nil }
        return letters.joined()
    }
}
