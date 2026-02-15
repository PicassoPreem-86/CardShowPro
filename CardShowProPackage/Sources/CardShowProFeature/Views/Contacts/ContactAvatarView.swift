import SwiftUI

/// Avatar view displaying contact initials in a circular badge
struct ContactAvatarView: View {
    let initials: String
    let size: CGSize
    var color: Color

    init(initials: String, size: CGSize = CGSize(width: 50, height: 50), color: Color = DesignSystem.Colors.electricBlue) {
        self.initials = initials
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color)

            Text(initials)
                .font(.system(size: size.width * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Previews

#Preview("Small Avatar") {
    ContactAvatarView(initials: "JS", size: CGSize(width: 40, height: 40))
        .padding()
}

#Preview("Large Avatar") {
    ContactAvatarView(initials: "AB", size: CGSize(width: 100, height: 100))
        .padding()
}
