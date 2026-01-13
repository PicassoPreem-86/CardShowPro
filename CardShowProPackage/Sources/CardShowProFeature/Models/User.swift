import Foundation
import SwiftData

/// Represents a CardShow Pro user with authentication and subscription information
@Model
final class User {
    // MARK: - Identification

    /// Unique identifier for the user (local)
    @Attribute(.unique) var id: UUID

    /// Supabase authentication ID
    var supabaseId: String?

    /// User's email address
    var email: String?

    /// Display name for the user
    var displayName: String?

    /// Apple User ID (from Sign in with Apple)
    var appleUserId: String?

    // MARK: - Subscription

    /// Current subscription status
    var subscriptionStatus: SubscriptionStatus

    /// When the current subscription expires (nil for free tier)
    var subscriptionExpiry: Date?

    /// Whether the user is currently in a trial period
    var isTrialActive: Bool

    /// When the trial started
    var trialStartDate: Date?

    /// RevenueCat customer ID (synced with Supabase ID)
    var revenueCatId: String?

    // MARK: - Usage Limits

    /// Total number of inventory cards user currently has
    var cardCount: Int

    /// When the user account was created
    var createdAt: Date

    /// Last time user logged in
    var lastLoginAt: Date

    // MARK: - Preferences

    /// User's preferred currency (USD, EUR, GBP, etc.)
    var preferredCurrency: String

    /// Whether analytics tracking is consented
    var analyticsConsent: Bool

    // MARK: - Computed Properties

    /// Whether the user can add more cards (Pro or under free limit)
    var canAddMoreCards: Bool {
        subscriptionStatus == .pro || subscriptionStatus == .trial || cardCount < 100
    }

    /// Whether the user has an active subscription (Pro or Trial)
    var hasActiveSubscription: Bool {
        subscriptionStatus == .pro || subscriptionStatus == .trial
    }

    /// Whether the subscription has expired
    var isSubscriptionExpired: Bool {
        guard let expiry = subscriptionExpiry else { return false }
        return Date() > expiry
    }

    /// Days remaining in trial (0 if not in trial)
    var trialDaysRemaining: Int {
        guard isTrialActive, let startDate = trialStartDate else { return 0 }
        let trialEndDate = Calendar.current.date(byAdding: .day, value: 14, to: startDate)!
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
        return max(0, daysRemaining)
    }

    // MARK: - Initialization

    init(
        email: String? = nil,
        displayName: String? = nil,
        appleUserId: String? = nil,
        supabaseId: String? = nil
    ) {
        self.id = UUID()
        self.email = email
        self.displayName = displayName
        self.appleUserId = appleUserId
        self.supabaseId = supabaseId
        self.subscriptionStatus = .free
        self.isTrialActive = false
        self.cardCount = 0
        self.createdAt = Date()
        self.lastLoginAt = Date()
        self.preferredCurrency = "USD"
        self.analyticsConsent = false
    }
}

// MARK: - Subscription Status

/// User's subscription tier
enum SubscriptionStatus: String, Codable, Sendable {
    /// Free tier (up to 100 cards, basic features)
    case free

    /// 14-day free trial (full Pro features)
    case trial

    /// Active Pro subscription ($9.99/month)
    case pro

    /// Subscription expired or payment failed
    case expired

    /// Subscription canceled (grace period)
    case canceled

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .trial: return "Trial"
        case .pro: return "Pro"
        case .expired: return "Expired"
        case .canceled: return "Canceled"
        }
    }

    var icon: String {
        switch self {
        case .free: return "person.crop.circle"
        case .trial: return "sparkles"
        case .pro: return "star.circle.fill"
        case .expired: return "exclamationmark.triangle"
        case .canceled: return "xmark.circle"
        }
    }
}

// MARK: - User Extensions

extension User {
    /// Check if user can access a specific feature
    func canAccess(_ feature: Feature) -> Bool {
        switch feature {
        case .priceLookup, .basicInventory:
            return true  // Available to all users

        case .unlimitedInventory:
            return hasActiveSubscription || cardCount < 100

        case .vendorMode, .crm, .advancedAnalytics, .exportData, .tradeAnalyzer, .grading:
            return hasActiveSubscription

        case .aiFeatures:
            return subscriptionStatus == .pro  // No trial for AI features
        }
    }

    /// Update subscription status from RevenueCat
    func updateSubscription(
        status: SubscriptionStatus,
        expiry: Date? = nil,
        isTrialActive: Bool = false,
        trialStartDate: Date? = nil
    ) {
        self.subscriptionStatus = status
        self.subscriptionExpiry = expiry
        self.isTrialActive = isTrialActive
        self.trialStartDate = trialStartDate
    }
}

// MARK: - Features Enum

/// App features that can be gated by subscription tier
enum Feature: String, CaseIterable, Sendable {
    case priceLookup
    case basicInventory
    case unlimitedInventory
    case vendorMode
    case crm
    case advancedAnalytics
    case exportData
    case tradeAnalyzer
    case grading
    case aiFeatures

    var displayName: String {
        switch self {
        case .priceLookup: return "Price Lookup"
        case .basicInventory: return "Basic Inventory (100 cards)"
        case .unlimitedInventory: return "Unlimited Inventory"
        case .vendorMode: return "Vendor Mode"
        case .crm: return "Customer CRM"
        case .advancedAnalytics: return "Advanced Analytics"
        case .exportData: return "Data Export"
        case .tradeAnalyzer: return "Trade Analyzer"
        case .grading: return "Grading Management"
        case .aiFeatures: return "AI Features"
        }
    }

    var icon: String {
        switch self {
        case .priceLookup: return "dollarsign.circle"
        case .basicInventory: return "square.stack"
        case .unlimitedInventory: return "square.stack.fill"
        case .vendorMode: return "storefront"
        case .crm: return "person.2"
        case .advancedAnalytics: return "chart.xyaxis.line"
        case .exportData: return "square.and.arrow.up"
        case .tradeAnalyzer: return "arrow.left.arrow.right"
        case .grading: return "star.leadinghalf.filled"
        case .aiFeatures: return "sparkles"
        }
    }

    var requiresPro: Bool {
        switch self {
        case .priceLookup, .basicInventory:
            return false
        default:
            return true
        }
    }
}
