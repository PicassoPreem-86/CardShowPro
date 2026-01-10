import SwiftUI

/// Skeleton loading view with shimmer animation effect
///
/// Usage:
/// ```swift
/// SkeletonView()
/// ```
@MainActor
public struct SkeletonView: View {
    @State private var isAnimating = false

    public init() {}

    public var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.SkeletonStyle.cornerRadius)
            .fill(DesignSystem.ComponentStyles.SkeletonStyle.baseColor)
            .overlay(
                ShimmerView()
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.ComponentStyles.SkeletonStyle.cornerRadius))
    }
}

/// Shimmer effect view for skeleton loading
@MainActor
struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            DesignSystem.ComponentStyles.SkeletonStyle.baseColor.opacity(0.0),
                            DesignSystem.ComponentStyles.SkeletonStyle.shimmerColor,
                            DesignSystem.ComponentStyles.SkeletonStyle.baseColor.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                .onAppear {
                    withAnimation(
                        .linear(duration: DesignSystem.ComponentStyles.SkeletonStyle.animationDuration)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 1.0
                    }
                }
        }
    }
}
