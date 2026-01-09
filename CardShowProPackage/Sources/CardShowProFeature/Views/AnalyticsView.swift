import SwiftUI

struct AnalyticsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Value Over Time Chart Placeholder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Portfolio Value")
                            .font(.headline)

                        VStack(spacing: 8) {
                            HStack(alignment: .bottom, spacing: 4) {
                                ForEach(0..<12) { index in
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue.gradient)
                                        .frame(height: CGFloat.random(in: 60...200))
                                }
                            }
                            .frame(height: 200)

                            HStack {
                                Text("Jan")
                                Spacer()
                                Text("Jun")
                                Spacer()
                                Text("Dec")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 5)
                    }

                    // Top Performers
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("🏆 Top Performers")
                                .font(.headline)
                            Spacer()
                            Button("See All") {}
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }

                        VStack(spacing: 12) {
                            PerformerRow(
                                rank: 1,
                                name: "Wembanyama Prizm",
                                gain: "+$540",
                                percentage: "82%"
                            )
                            PerformerRow(
                                rank: 2,
                                name: "Ohtani Chrome",
                                gain: "+$280",
                                percentage: "45%"
                            )
                            PerformerRow(
                                rank: 3,
                                name: "Edwards Prizm",
                                gain: "+$195",
                                percentage: "32%"
                            )
                        }
                    }

                    // Category Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("By Sport")
                            .font(.headline)

                        VStack(spacing: 8) {
                            CategoryBar(sport: "Basketball", percentage: 45, color: .orange)
                            CategoryBar(sport: "Baseball", percentage: 30, color: .blue)
                            CategoryBar(sport: "Football", percentage: 20, color: .green)
                            CategoryBar(sport: "Other", percentage: 5, color: .gray)
                        }
                    }

                    // Stats Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Stats")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatBox(title: "Avg Card Value", value: "$19.70")
                            StatBox(title: "Total Profit", value: "+$8,420")
                            StatBox(title: "Graded Cards", value: "342")
                            StatBox(title: "Hot Cards", value: "28")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
        }
    }
}

struct PerformerRow: View {
    let rank: Int
    let name: String
    let gain: String
    let percentage: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue.gradient)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(gain)
                    .font(.caption)
                    .foregroundStyle(.green)
            }

            Spacer()

            Text(percentage)
                .font(.headline)
                .foregroundStyle(.green)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct CategoryBar: View {
    let sport: String
    let percentage: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(sport)
                    .font(.subheadline)
                Spacer()
                Text("\(percentage)%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.gradient)
                        .frame(width: geometry.size.width * CGFloat(percentage) / 100)
                }
            }
            .frame(height: 8)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}
