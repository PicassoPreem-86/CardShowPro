import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    private var txType: TransactionType {
        transaction.transactionType
    }

    private var amountColor: Color {
        switch txType {
        case .sale:
            return DesignSystem.Colors.success
        case .purchase:
            return DesignSystem.Colors.error
        case .trade:
            return DesignSystem.Colors.warning
        case .consignment:
            return Color.purple
        case .refund:
            return .red
        }
    }

    private var typeColor: Color {
        switch txType {
        case .sale: return DesignSystem.Colors.success
        case .purchase: return .blue
        case .trade: return DesignSystem.Colors.warning
        case .consignment: return .purple
        case .refund: return .red
        }
    }

    private var amountPrefix: String {
        switch txType {
        case .sale: return "+"
        case .purchase: return "-"
        case .refund: return "-"
        case .trade, .consignment: return ""
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Type icon
            Image(systemName: txType.icon)
                .font(.title3)
                .foregroundStyle(typeColor)
                .frame(width: 36, height: 36)
                .background(typeColor.opacity(0.15))
                .clipShape(Circle())

            // Card info
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                Text(transaction.cardName.isEmpty ? "Unknown Card" : transaction.cardName)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: DesignSystem.Spacing.xxs) {
                    if !transaction.cardSetName.isEmpty {
                        Text(transaction.cardSetName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .lineLimit(1)
                    }

                    if let contactName = transaction.contactName, !contactName.isEmpty {
                        Text("·")
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                        Text(contactName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Amount and metadata
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xxxs) {
                Text("\(amountPrefix)\(transaction.formattedAmount)")
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.bold)
                    .foregroundStyle(amountColor)

                HStack(spacing: DesignSystem.Spacing.xxxs) {
                    if let platform = transaction.platform, !platform.isEmpty {
                        Text(platform)
                            .font(DesignSystem.Typography.captionSmall)
                            .fontWeight(.medium)
                            .foregroundStyle(DesignSystem.Colors.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.cyan.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text(transaction.formattedDate)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xxxs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(txType.rawValue), \(transaction.cardName), \(transaction.formattedAmount), \(transaction.formattedDate)")
    }
}
