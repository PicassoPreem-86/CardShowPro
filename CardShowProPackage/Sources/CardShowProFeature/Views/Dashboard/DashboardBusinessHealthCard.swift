import SwiftUI

struct DashboardBusinessHealthCard: View {
    @Binding var selectedTab: String
    @Binding var selectedPeriod: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with toggle
            HStack {
                // Toggle button
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = selectedTab == "Overview" ? "Performance" : "Overview"
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(selectedTab)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .rotationEffect(.degrees(selectedTab == "Performance" ? 180 : 0))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                // Currency indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 8)
                    Text("USD")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)

            // Main content
            VStack(alignment: .leading, spacing: 8) {
                if selectedTab == "Overview" {
                    // Overview tab content
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Portfolio")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                            Text("Main")
                                .font(.subheadline)
                                .foregroundStyle(.cyan)
                                .fontWeight(.semibold)
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("$18,920")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Button(action: {}) {
                                Image(systemName: "eye.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("+$1,247.50 in the last 7 days")
                            .font(.subheadline)
                            .foregroundStyle(.cyan)
                    }
                    .frame(height: 140, alignment: .top)
                    .padding(.horizontal, 20)
                } else {
                    // Performance tab content
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Portfolio")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                Text("Main")
                                    .font(.subheadline)
                                    .foregroundStyle(.cyan)
                                    .fontWeight(.semibold)
                            }

                            Spacer()

                            // Unrealized dropdown
                            HStack(spacing: 4) {
                                Text("Unrealized")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            Text("+$356.91")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.cyan)

                            Button(action: {}) {
                                Image(systemName: "eye.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack(spacing: 16) {
                            Text("Paid $1,295.00")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Market Value $1,651.91")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 140, alignment: .top)
                    .padding(.horizontal, 20)
                }

                // Area chart placeholder
                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        ZStack(alignment: .bottom) {
                            // Gradient fill
                            Path { path in
                                let width = geometry.size.width
                                let height = geometry.size.height

                                path.move(to: CGPoint(x: 0, y: height * 0.7))
                                path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.5))
                                path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.3))
                                path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.4))
                                path.addLine(to: CGPoint(x: width, y: height * 0.2))
                                path.addLine(to: CGPoint(x: width, y: height))
                                path.addLine(to: CGPoint(x: 0, y: height))
                                path.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity(0.3),
                                        Color.cyan.opacity(0.05)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            // Line
                            Path { path in
                                let width = geometry.size.width
                                let height = geometry.size.height

                                path.move(to: CGPoint(x: 0, y: height * 0.7))
                                path.addLine(to: CGPoint(x: width * 0.25, y: height * 0.5))
                                path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.3))
                                path.addLine(to: CGPoint(x: width * 0.75, y: height * 0.4))
                                path.addLine(to: CGPoint(x: width, y: height * 0.2))
                            }
                            .stroke(Color.cyan, lineWidth: 2.5)
                        }
                    }
                    .frame(height: 160)
                }
                .padding(.horizontal, 20)

                // Time period selector
                HStack(spacing: 16) {
                    ForEach(["1D", "7D", "1M", "3M", "6M", "MAX"], id: \.self) { period in
                        PeriodButton(title: period, isSelected: selectedPeriod == period) {
                            selectedPeriod = period
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}
