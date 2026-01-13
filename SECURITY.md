# SECURITY.md - Security Best Practices

**Document Version**: 1.0
**Last Updated**: January 2026
**Target**: CardShow Pro iOS App
**Platform**: iOS 17.0+

---

## Table of Contents

1. [Security Philosophy](#security-philosophy)
2. [Data Encryption & Storage](#data-encryption--storage)
3. [API Key Management](#api-key-management)
4. [Privacy Policy Requirements](#privacy-policy-requirements)
5. [App Transport Security (ATS)](#app-transport-security-ats)
6. [Authentication & Authorization](#authentication--authorization)
7. [Secure Coding Practices](#secure-coding-practices)
8. [Third-Party Dependencies](#third-party-dependencies)
9. [Security Audit Checklist](#security-audit-checklist)
10. [Vulnerability Reporting](#vulnerability-reporting)
11. [GDPR/CCPA Compliance](#gdprccpa-compliance)
12. [Incident Response Plan](#incident-response-plan)

---

## Security Philosophy

CardShow Pro follows a **defense-in-depth** security strategy with these core principles:

1. **Privacy by Design**: Minimize data collection and maximize user control
2. **Zero Trust**: Validate all inputs, encrypt all sensitive data
3. **Fail Securely**: Graceful degradation without exposing sensitive information
4. **Least Privilege**: Grant minimum necessary permissions
5. **Transparency**: Clear communication about data usage and storage

### Security Goals

- **Confidentiality**: Protect user inventory, pricing, and customer data
- **Integrity**: Ensure accuracy of pricing data and sales calculations
- **Availability**: Maintain offline functionality and data sync reliability
- **Accountability**: Audit trail for critical operations

---

## Data Encryption & Storage

### SwiftData Encryption

All persistent data is stored using SwiftData, which leverages Core Data's built-in encryption when device encryption is enabled.

#### Automatic Protection

```swift
// SwiftData automatically uses iOS data protection
// when the device has a passcode enabled

@Model
final class InventoryCard {
    var name: String
    var purchaseCost: Double?  // Automatically encrypted at rest
    var marketValue: Double
}
```

**iOS Data Protection Levels**:

- **Complete Protection** (default): File inaccessible when device locked
- **Complete Unless Open**: File accessible if opened before lock
- **Complete Until First Unlock**: File accessible after first device unlock
- **No Protection**: Always accessible (avoid for sensitive data)

#### File System Encryption

For files stored outside SwiftData:

```swift
import Foundation

func saveSecureFile(data: Data, filename: String) throws {
    let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(filename)

    try data.write(
        to: fileURL,
        options: [.completeFileProtection]  // Enable encryption
    )
}
```

### Keychain Storage

Use Keychain for all sensitive credentials and API keys.

#### Keychain Wrapper Implementation

```swift
import Security
import Foundation

actor KeychainManager {
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case unexpectedData
        case unhandledError(status: OSStatus)
    }

    // MARK: - Save

    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unexpectedData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status != errSecDuplicateItem else {
            throw KeychainError.duplicateItem
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // MARK: - Retrieve

    func retrieve(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }

        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        guard let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }

        return value
    }

    // MARK: - Delete

    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}
```

#### Usage Example

```swift
@Observable
final class APIKeyManager {
    private let keychain = KeychainManager()

    func storePokemonTCGAPIKey(_ key: String) async throws {
        try await keychain.save(key: "pokemontcg_api_key", value: key)
    }

    func retrievePokemonTCGAPIKey() async throws -> String {
        try await keychain.retrieve(key: "pokemontcg_api_key")
    }
}
```

### Never Store in UserDefaults

**❌ NEVER store sensitive data in UserDefaults:**

```swift
// WRONG - Never do this!
UserDefaults.standard.set(apiKey, forKey: "api_key")
UserDefaults.standard.set(userPassword, forKey: "password")
```

**✅ Always use Keychain:**

```swift
// CORRECT
try await keychain.save(key: "api_key", value: apiKey)
```

### Memory Safety

```swift
// Use SecureString for sensitive data in memory
// Note: Swift doesn't have built-in SecureString, so minimize exposure

func processAPIKey(_ key: String) {
    // Process immediately
    let request = buildRequest(with: key)

    // Don't store in long-lived properties
    // Let Swift's ARC deallocate as soon as possible
}
```

---

## API Key Management

### Configuration Strategy

**Development vs Production Keys**

```swift
// Config/APIKeys.swift
enum APIKeys {
    static var pokemonTCGKey: String {
        #if DEBUG
        return "dev_pokemon_tcg_key_here"
        #else
        // Retrieve from Keychain in production
        return ""  // Never hardcode production keys
        #endif
    }
}
```

### Environment Variables (Development Only)

For local development, use Xcode schemes to inject environment variables:

1. **Xcode → Edit Scheme → Run → Arguments**
2. Add Environment Variables:
   - `POKEMON_TCG_API_KEY`: `your_dev_key_here`
   - `TCGDEX_API_KEY`: `your_dev_key_here`

```swift
enum EnvironmentConfig {
    static func getAPIKey(for service: String) -> String? {
        ProcessInfo.processInfo.environment[service]
    }
}
```

### Secrets Management (Production)

**Option 1: Manual Keychain Entry (MVP)**

For V1, manually add production API keys via Settings screen:

```swift
struct APISettingsView: View {
    @State private var apiKey = ""
    private let keychain = KeychainManager()

    var body: some View {
        Form {
            Section("API Configuration") {
                SecureField("Pokemon TCG API Key", text: $apiKey)

                Button("Save") {
                    Task {
                        try? await keychain.save(
                            key: "pokemontcg_api_key",
                            value: apiKey
                        )
                    }
                }
            }
        }
    }
}
```

**Option 2: Backend Key Distribution (V2+)**

For future versions, distribute keys from secure backend:

```swift
actor SecureKeyService {
    func fetchAPIKeys() async throws -> [String: String] {
        // 1. Authenticate user with backend
        // 2. Backend returns encrypted API keys
        // 3. Store in Keychain
        // 4. Never expose keys in client code

        fatalError("Implement in V2")
    }
}
```

### Code Obfuscation (Optional)

For additional protection of free-tier API keys:

```bash
# Use SwiftShield or similar for production builds
# https://github.com/rockbruno/swiftshield
```

### Git Security

**❌ NEVER commit API keys to git**

Add to `.gitignore`:

```gitignore
# API Keys
Config/APIKeys.swift
*.plist
*secrets*
.env
```

**Pre-commit Hook**

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh

# Check for potential API keys
if git diff --cached | grep -iE "(api[_-]?key|secret|password|token)" | grep -v "Config/APIKeys.swift"; then
    echo "ERROR: Potential API key detected in commit"
    echo "Please remove sensitive data before committing"
    exit 1
fi
```

Make executable:

```bash
chmod +x .git/hooks/pre-commit
```

---

## Privacy Policy Requirements

### Required Disclosures (App Store)

CardShow Pro must disclose data collection in App Privacy section:

#### Data Collected

| Data Type | Purpose | Linked to User | Used for Tracking |
|-----------|---------|----------------|-------------------|
| Camera | Card scanning | No | No |
| Photos | Card image analysis | No | No |
| User Content | Inventory data | Yes | No |
| Identifiers | Subscription management | Yes | No |
| Usage Data | App analytics | No | Yes |

#### Privacy Labels Implementation

1. **App Store Connect → App Privacy**
2. Select "Camera Access":
   - Purpose: "Card recognition and price lookup"
   - Not linked to user identity
   - Not used for tracking
3. Select "Photos":
   - Purpose: "Card image analysis and inventory photos"
   - Not linked to user identity
   - Not used for tracking

### Info.plist Privacy Descriptions

**Required permission strings:**

```xml
<!-- CardShowPro/Info.plist -->
<dict>
    <!-- Camera Access -->
    <key>NSCameraUsageDescription</key>
    <string>CardShow Pro uses your camera to scan trading cards for quick price lookups and inventory management.</string>

    <!-- Photo Library Access -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>CardShow Pro needs access to your photo library to analyze card images and add photos to your inventory.</string>

    <!-- Photo Library Add Only (Optional) -->
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>CardShow Pro can save card images to your photo library.</string>
</dict>
```

### Privacy Policy Document

**Required before App Store submission.**

Create `PrivacyPolicy.md` with these sections:

1. **Information Collection**
   - What data is collected (inventory, images, usage)
   - Why it's collected (app functionality, analytics)
   - How it's collected (user input, camera, API calls)

2. **Data Storage**
   - Where data is stored (on-device SwiftData, Keychain)
   - How long it's retained (until user deletes)
   - Encryption methods (iOS data protection)

3. **Third-Party Services**
   - PokemonTCG.io (card data)
   - TCGDex (pricing data)
   - Google Gemini (AI features in V3)
   - RevenueCat (subscription management)

4. **User Rights**
   - Access your data (export feature)
   - Delete your data (account deletion)
   - Opt out of analytics

5. **Contact Information**
   - Email: privacy@cardshowpro.com
   - Response time: 48 hours

**Host at**: `https://cardshowpro.com/privacy`

### App Tracking Transparency (ATT)

If using analytics that track across apps:

```swift
import AppTrackingTransparency

func requestTrackingPermission() async {
    if #available(iOS 14, *) {
        let status = await ATTrackingManager.requestTrackingAuthorization()

        switch status {
        case .authorized:
            // Enable cross-app tracking analytics
            enableAnalytics()
        case .denied, .restricted, .notDetermined:
            // Use privacy-preserving analytics only
            enablePrivacyPreservingAnalytics()
        @unknown default:
            break
        }
    }
}
```

Add to Info.plist:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This helps us improve CardShow Pro by understanding how you use the app.</string>
```

---

## App Transport Security (ATS)

### Default Configuration (Secure)

iOS requires HTTPS by default. All API endpoints MUST use TLS 1.2+.

```xml
<!-- Info.plist -->
<dict>
    <key>NSAppTransportSecurity</key>
    <dict>
        <!-- Default: require HTTPS for all connections -->
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
</dict>
```

### API Endpoint Requirements

All CardShow Pro APIs use HTTPS:

- ✅ `https://api.pokemontcg.io` - TLS 1.3
- ✅ `https://api.tcgdex.net` - TLS 1.2
- ✅ `https://api.scryfall.com` - TLS 1.3
- ✅ `https://generativelanguage.googleapis.com` - TLS 1.3

### Certificate Pinning (V2+)

For enhanced security in production:

```swift
import Foundation

final class PinnedURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              challenge.protectionSpace.host == "api.pokemontcg.io" else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Validate certificate against pinned public key
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }
}
```

---

## Authentication & Authorization

### User Authentication (V2+)

When adding user accounts:

```swift
import AuthenticationServices

@Observable
final class AuthenticationService {
    var currentUser: User?

    // MARK: - Sign in with Apple

    func signInWithApple() async throws {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]

        // Present authorization controller
        // Store user ID in Keychain
        // Never store passwords
    }

    // MARK: - Biometric Authentication

    func authenticateWithBiometrics() async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw AuthError.biometricsNotAvailable
        }

        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Unlock your CardShow Pro inventory"
        )
    }
}
```

### Session Management

```swift
@Observable
final class SessionManager {
    private let sessionTimeout: TimeInterval = 3600  // 1 hour
    private var lastActivityDate = Date()

    func validateSession() -> Bool {
        let elapsed = Date().timeIntervalSince(lastActivityDate)

        if elapsed > sessionTimeout {
            // Session expired, require re-authentication
            return false
        }

        lastActivityDate = Date()
        return true
    }
}
```

### Authorization Patterns

```swift
enum UserPermission {
    case viewInventory
    case editInventory
    case deleteInventory
    case exportData
    case manageSubscription
}

protocol Authorizable {
    func hasPermission(_ permission: UserPermission) -> Bool
}

extension User: Authorizable {
    func hasPermission(_ permission: UserPermission) -> Bool {
        switch permission {
        case .viewInventory:
            return true  // All users
        case .editInventory:
            return subscriptionActive || inventoryCount < 100  // Free tier limit
        case .deleteInventory:
            return true
        case .exportData:
            return subscriptionActive  // Pro feature
        case .manageSubscription:
            return true
        }
    }
}
```

---

## Secure Coding Practices

### Input Validation

**Always validate user input:**

```swift
struct CardSearchValidator {
    enum ValidationError: Error {
        case emptyQuery
        case queryTooShort
        case queryTooLong
        case invalidCharacters
    }

    static func validate(query: String) throws {
        // 1. Check length
        guard !query.isEmpty else {
            throw ValidationError.emptyQuery
        }

        guard query.count >= 2 else {
            throw ValidationError.queryTooShort
        }

        guard query.count <= 100 else {
            throw ValidationError.queryTooLong
        }

        // 2. Sanitize special characters
        let allowedCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-'"))

        let queryCharacters = CharacterSet(charactersIn: query)

        guard allowedCharacters.isSuperset(of: queryCharacters) else {
            throw ValidationError.invalidCharacters
        }
    }
}
```

### SQL Injection Prevention

SwiftData uses predicates, which are safe from injection:

```swift
// ✅ Safe - SwiftData predicates are parameterized
@Query(filter: #Predicate<InventoryCard> { card in
    card.name.contains(searchTerm)
})
var cards: [InventoryCard]
```

**Never construct raw SQL:**

```swift
// ❌ NEVER do this - vulnerable to injection
let query = "SELECT * FROM cards WHERE name = '\(userInput)'"
```

### XSS Prevention (Web Views)

If using WKWebView for displaying web content:

```swift
import WebKit

final class SecureWebViewController: UIViewController {
    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()

        // Disable JavaScript unless absolutely necessary
        config.preferences.javaScriptEnabled = false

        // Enable safe browsing
        config.preferences.fraudulentWebsiteWarningEnabled = true

        return WKWebView(frame: .zero, configuration: config)
    }()

    func loadContent(_ html: String) {
        // Sanitize HTML before loading
        let sanitized = sanitizeHTML(html)
        webView.loadHTMLString(sanitized, baseURL: nil)
    }

    private func sanitizeHTML(_ html: String) -> String {
        // Remove <script> tags and event handlers
        var sanitized = html
        sanitized = sanitized.replacingOccurrences(
            of: "<script[^>]*>.*?</script>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        return sanitized
    }
}
```

### Logging Security

**Never log sensitive data:**

```swift
import os.log

extension Logger {
    static let api = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "API"
    )

    static let security = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "Security"
    )
}

// Usage
func performAPIRequest(apiKey: String, endpoint: String) {
    // ❌ NEVER log API keys or tokens
    // Logger.api.debug("API Key: \(apiKey)")

    // ✅ Log only non-sensitive info
    Logger.api.debug("Fetching from endpoint: \(endpoint)")
}

func handleAuthenticationError(_ error: Error) {
    // ❌ Don't expose detailed auth errors to users
    // showAlert("Authentication failed: \(error.localizedDescription)")

    // ✅ Log detailed error, show generic message
    Logger.security.error("Auth failed: \(error.localizedDescription)")
    showAlert("Authentication failed. Please try again.")
}
```

### Error Handling

**Fail securely without exposing internals:**

```swift
enum APIError: LocalizedError {
    case networkError
    case invalidResponse
    case serverError
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to connect. Please check your internet connection."
        case .invalidResponse:
            return "Received invalid data. Please try again."
        case .serverError:
            return "Server error. Please try again later."
        case .unauthorized:
            return "Authentication required. Please sign in."
        }
    }

    // Internal debugging info (never shown to user)
    var debugDescription: String {
        switch self {
        case .networkError:
            return "URLSession error - network unavailable"
        case .invalidResponse:
            return "JSON decode failed - schema mismatch"
        case .serverError:
            return "HTTP 500 - upstream API failure"
        case .unauthorized:
            return "HTTP 401 - invalid or expired token"
        }
    }
}
```

---

## Third-Party Dependencies

### Dependency Audit

Regularly audit all third-party packages for vulnerabilities.

**Current Dependencies (V1)**:
- None (using native Swift Package Manager only)

**Planned Dependencies (V2+)**:
- RevenueCat (subscription management)
- TelemetryDeck (privacy-preserving analytics)

### Dependency Security Checklist

Before adding any third-party dependency:

- [ ] Check GitHub stars (>1000 preferred)
- [ ] Check last commit date (<6 months preferred)
- [ ] Review open issues for security concerns
- [ ] Verify license compatibility (MIT, Apache 2.0)
- [ ] Check for known vulnerabilities (GitHub Security Advisories)
- [ ] Review source code for suspicious patterns
- [ ] Pin to specific version (never use `branch: main`)

### Package.swift Security

```swift
// Package.swift
dependencies: [
    // ✅ Pin to specific version
    .package(
        url: "https://github.com/RevenueCat/purchases-ios",
        exact: "4.35.0"
    ),

    // ❌ Never use branch or version range for security-critical packages
    // .package(url: "...", branch: "main")
    // .package(url: "...", from: "4.0.0")
]
```

### Subresource Integrity (SRI)

For any web content loaded in app:

```swift
func verifyIntegrity(of data: Data, expectedHash: String) -> Bool {
    let hash = SHA256.hash(data: data)
    let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
    return hashString == expectedHash
}
```

---

## Security Audit Checklist

Use this checklist before each release.

### Pre-Release Security Review

#### Code Security
- [ ] No hardcoded API keys or secrets
- [ ] No sensitive data logged to console
- [ ] All user inputs validated and sanitized
- [ ] All API calls use HTTPS
- [ ] Error messages don't expose system internals
- [ ] No force-unwraps in production code paths
- [ ] All file operations use data protection
- [ ] Keychain used for all sensitive data storage

#### Privacy Compliance
- [ ] Privacy Policy URL set in App Store Connect
- [ ] All required Info.plist permission strings present
- [ ] App Privacy labels accurate and complete
- [ ] No tracking without user consent
- [ ] Data collection minimized and disclosed
- [ ] User can export/delete their data

#### Network Security
- [ ] All API endpoints use TLS 1.2+
- [ ] Certificate pinning implemented (if applicable)
- [ ] No arbitrary loads in ATS configuration
- [ ] API rate limiting implemented client-side
- [ ] Timeout values set appropriately

#### Authentication & Authorization
- [ ] Biometric authentication available (if applicable)
- [ ] Session timeout implemented
- [ ] Token refresh logic working correctly
- [ ] Authorization checks on sensitive operations
- [ ] Logout fully clears session data

#### Data Protection
- [ ] SwiftData encryption enabled via device passcode
- [ ] Sensitive files use `.completeFileProtection`
- [ ] No sensitive data cached in NSCache
- [ ] Screenshots blocked on sensitive screens (if needed)
- [ ] Copy/paste disabled for sensitive fields (if needed)

#### Third-Party Security
- [ ] All dependencies pinned to specific versions
- [ ] Dependency licenses reviewed
- [ ] No known vulnerabilities in dependencies
- [ ] Third-party SDK privacy policies reviewed

#### Build Security
- [ ] Debug code disabled in release builds
- [ ] Code signing configured correctly
- [ ] Bitcode enabled (if applicable)
- [ ] Strip debug symbols in release build
- [ ] Obfuscation enabled (if using)

---

## Vulnerability Reporting

### Security Contact

**Email**: security@cardshowpro.com
**Response Time**: 48 hours maximum
**PGP Key**: (Add when available)

### Responsible Disclosure Policy

We welcome security researchers to report vulnerabilities responsibly.

#### Reporting Process

1. **Email** security@cardshowpro.com with:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (optional)

2. **Do NOT**:
   - Publicly disclose before we patch
   - Access user data beyond proof-of-concept
   - Perform DoS attacks
   - Social engineer staff or users

3. **We Will**:
   - Acknowledge within 48 hours
   - Provide estimated fix timeline within 1 week
   - Credit you in release notes (if desired)
   - Consider bounty program in future

#### Severity Classification

| Severity | Examples | Response Time |
|----------|----------|---------------|
| Critical | Remote code execution, data breach | 24 hours |
| High | Authentication bypass, data exposure | 72 hours |
| Medium | XSS, CSRF, information disclosure | 1 week |
| Low | UI redressing, minor info leak | 2 weeks |

---

## GDPR/CCPA Compliance

### Data Subject Rights

CardShow Pro must support these user rights:

#### 1. Right to Access (GDPR Art. 15)

```swift
@Observable
final class DataExportService {
    func exportUserData() async throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let exportData = UserDataExport(
            inventory: fetchAllInventory(),
            sales: fetchAllSales(),
            trades: fetchAllTrades(),
            contacts: fetchAllContacts(),
            settings: fetchSettings()
        )

        let data = try encoder.encode(exportData)

        // Save to temporary file
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cardshowpro-data-export.json")

        try data.write(to: fileURL)

        return fileURL
    }
}

struct UserDataExport: Codable {
    let inventory: [InventoryCard]
    let sales: [SalesHistory]
    let trades: [TradeHistory]
    let contacts: [Contact]
    let settings: UserSettings
    let exportDate: Date = Date()
    let version: String = "1.0"
}
```

#### 2. Right to Erasure (GDPR Art. 17)

```swift
@Observable
final class AccountDeletionService {
    @MainActor
    func deleteAllUserData(context: ModelContext) async throws {
        // 1. Delete all SwiftData models
        try context.delete(model: InventoryCard.self)
        try context.delete(model: SalesHistory.self)
        try context.delete(model: TradeHistory.self)
        try context.delete(model: Contact.self)
        try context.delete(model: WantListItem.self)

        // 2. Delete all Keychain items
        let keychain = KeychainManager()
        try await keychain.delete(key: "pokemontcg_api_key")
        try await keychain.delete(key: "user_session")

        // 3. Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        // 4. Delete cached files
        clearCaches()

        // 5. Save changes
        try context.save()
    }

    private func clearCaches() {
        let fileManager = FileManager.default

        // Clear caches directory
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            try? fileManager.removeItem(at: cachesURL)
        }
    }
}
```

#### 3. Right to Data Portability (GDPR Art. 20)

Export in machine-readable format (JSON, CSV):

```swift
func exportAsCSV() -> String {
    var csv = "Name,Set,Number,Condition,Purchase Cost,Market Value,Profit\n"

    for card in inventory {
        csv += "\(card.name),\(card.setName),\(card.cardNumber),"
        csv += "\(card.condition),\(card.purchaseCost ?? 0),\(card.marketValue),"
        csv += "\(card.profit)\n"
    }

    return csv
}
```

### Data Retention Policy

**CardShow Pro Retention Periods**:

| Data Type | Retention Period | Deletion Trigger |
|-----------|------------------|------------------|
| Inventory Data | Until user deletes | Manual deletion or account deletion |
| Sales History | Until user deletes | Manual deletion or account deletion |
| Cached Prices | 24 hours | Automatic expiration |
| API Keys (Keychain) | Until user deletes | Account deletion |
| Analytics Data | 90 days | Automatic rolling deletion |
| Crash Logs | 30 days | Automatic deletion |

### Cookie/Tracking Consent

If implementing analytics:

```swift
@Observable
final class ConsentManager {
    @AppStorage("analytics_consent") private var analyticsConsent = false
    @AppStorage("personalization_consent") private var personalizationConsent = false

    func requestConsent() {
        // Show consent UI on first launch
        // Store choices in AppStorage
        // Apply choices to analytics services
    }

    func withdrawConsent() {
        analyticsConsent = false
        personalizationConsent = false

        // Disable all tracking
        // Delete existing analytics data
    }
}
```

---

## Incident Response Plan

### Security Incident Classification

**Tier 1 - Critical**
- Data breach affecting >100 users
- Complete service outage
- Unauthorized access to production systems

**Tier 2 - High**
- Data breach affecting <100 users
- Authentication bypass discovered
- Significant data loss

**Tier 3 - Medium**
- Vulnerability discovered but not exploited
- Service degradation
- Minor data exposure

### Incident Response Steps

#### 1. Detection & Analysis (0-2 hours)
- [ ] Identify scope of incident
- [ ] Determine affected users
- [ ] Assess data compromised
- [ ] Document timeline

#### 2. Containment (2-6 hours)
- [ ] Disable compromised features
- [ ] Revoke compromised API keys
- [ ] Block malicious actors
- [ ] Preserve evidence/logs

#### 3. Eradication (6-24 hours)
- [ ] Patch vulnerability
- [ ] Remove unauthorized access
- [ ] Update credentials
- [ ] Deploy fix

#### 4. Recovery (24-48 hours)
- [ ] Restore normal operations
- [ ] Monitor for recurrence
- [ ] Verify data integrity
- [ ] Re-enable features

#### 5. Communication (Ongoing)
- [ ] Notify affected users (email)
- [ ] Update status page
- [ ] Coordinate with Apple if needed
- [ ] File required breach notifications (GDPR: 72 hours)

#### 6. Post-Incident Review (Within 1 week)
- [ ] Root cause analysis
- [ ] Update security procedures
- [ ] Implement preventive measures
- [ ] Train team on lessons learned

### Notification Templates

#### User Notification (Data Breach)

```
Subject: Important Security Notice - CardShow Pro

Dear CardShow Pro User,

We are writing to inform you of a security incident that may have affected
your account.

WHAT HAPPENED:
On [DATE], we discovered [BRIEF DESCRIPTION].

WHAT INFORMATION WAS INVOLVED:
[LIST SPECIFIC DATA TYPES - e.g., inventory data, contact information]

WHAT WE'RE DOING:
- Patched the vulnerability on [DATE]
- Implemented additional security measures
- Notified relevant authorities

WHAT YOU SHOULD DO:
1. Review your inventory for any unauthorized changes
2. Change your password if you use the same password elsewhere
3. Monitor your account for suspicious activity

We sincerely apologize for this incident and are committed to protecting
your data.

For questions, contact: security@cardshowpro.com

Sincerely,
CardShow Pro Security Team
```

---

## Appendix: Security Tools & Resources

### Static Analysis Tools

**SwiftLint**: Enforce secure coding standards

```yaml
# .swiftlint.yml
opt_in_rules:
  - force_unwrapping  # Catch force unwraps
  - weak_delegate     # Prevent retain cycles
  - empty_string      # Use isEmpty instead of == ""

disabled_rules:
  - line_length       # Can be overly strict

force_unwrapping:
  severity: error     # Fail build on force unwrap
```

**SonarQube**: Comprehensive code quality analysis

### Dynamic Analysis Tools

**Instruments**: Xcode's built-in profiler
- Leaks (memory leaks)
- Zombies (use-after-free)
- Network (HTTPS usage)

**Burp Suite**: Network traffic analysis
- Verify all requests use HTTPS
- Check for sensitive data in requests
- Test API authentication

### Penetration Testing

**Recommended Schedule**:
- Before V1 launch: Manual security review
- V1.0 release: Professional penetration test
- Quarterly: Automated vulnerability scans
- Annually: Full penetration test

### Security Training

**Team Resources**:
- [OWASP Mobile Security Testing Guide](https://mobile-security.gitbook.io/mobile-security-testing-guide/)
- [Apple Platform Security Guide](https://support.apple.com/guide/security/welcome/web)
- [Swift.org Security Best Practices](https://swift.org/documentation/security/)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | January 2026 | Initial security documentation |

---

## Next Steps

1. **Review this document** with entire development team
2. **Complete Pre-Release Security Checklist** before V1 submission
3. **Create Privacy Policy** and host at cardshowpro.com/privacy
4. **Set up security email** security@cardshowpro.com
5. **Schedule first security audit** before App Store submission
6. **Implement Keychain storage** for all API keys
7. **Add Info.plist privacy strings** for camera/photos

---

**Remember: Security is not a feature—it's a fundamental requirement. Review and update this document quarterly.**
