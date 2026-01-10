# Ximilar API Setup Guide

This guide will help you set up the Ximilar Visual AI API for CardShowPro to enable real trading card recognition with 97%+ accuracy.

## Quick Start

1. **Sign up for Ximilar** (Free tier: 1,000 credits/month)
   - Visit: https://ximilar.com/signup
   - Create a free account (no credit card required for free tier)
   - Verify your email address

2. **Get Your API Token**
   - Log in to https://dashboard.ximilar.com
   - Navigate to **Settings** → **API Tokens**
   - Click **Create New Token**
   - Copy your token (starts with `Token_...`)

3. **Configure CardShowPro**
   - Open `CardShowProPackage/Sources/CardShowProFeature/Services/CardRecognitionService.swift`
   - Line 19: Replace `"YOUR_XIMILAR_API_TOKEN_HERE"` with your actual token
   - Line 20: Set `useRealAPI = true` to enable live recognition

   ```swift
   private let apiToken = "Token_abc123xyz456..."  // Your actual token
   private let useRealAPI = true  // Enable live API
   ```

4. **Build and Test**
   - Run the app in Simulator or on a device
   - Select Pokemon or One Piece game from the camera view
   - Point camera at a trading card
   - Tap capture button to scan

## Supported Features

### Card Recognition (tcg_id endpoint)
- **Pokemon Cards**: 97%+ accuracy on modern sets (Base Set to present)
- **One Piece Cards**: Supports Romance Dawn, Paramount War, and newer sets
- **Returns**: Card name, set name, card number, rarity, confidence score

### Graded Slab Recognition (slab_id endpoint)
- **PSA**: Professional Sports Authenticator
- **BGS**: Beckett Grading Services (with sub-grades)
- **CGC**: Certified Guaranty Company
- **SGC**: Sportscard Guaranty Company
- **Returns**: Card info + grading company + grade + certification number

## API Usage & Cost

### Free Tier
- **1,000 credits/month** (resets monthly)
- **1 credit per card** recognition
- **1 credit per slab** recognition
- Perfect for testing and small-scale personal use

### Paid Tiers
- **Starter**: $49/month - 5,000 credits
- **Professional**: $199/month - 25,000 credits
- **Enterprise**: Custom pricing for high-volume usage

### Usage Estimate
- **100 cards/day** = 3,000 credits/month → Starter plan
- **500 cards/day** = 15,000 credits/month → Professional plan
- **1,000+ cards/day** = Contact Ximilar for Enterprise pricing

## Testing Your Setup

### Test with Pokemon Cards
```
Expected results:
- Charizard cards: 95%+ confidence
- Modern holos: 90%+ confidence
- Common cards: 85%+ confidence
- Very old/damaged: 70%+ confidence (may need manual verification)
```

### Test with One Piece Cards
```
Expected results:
- Romance Dawn cards: 90%+ confidence
- Paramount War cards: 90%+ confidence
- Leader cards: 92%+ confidence
- Rare/Alt Art: 88%+ confidence
```

### Test with Graded Slabs
```
Expected results:
- PSA 10 modern: 95%+ confidence on both card and grade
- BGS 9.5: 93%+ confidence with sub-grades
- CGC 9: 92%+ confidence
- Vintage slabs: 85%+ confidence (label may be harder to read)
```

## Troubleshooting

### "Invalid API Token" Error
- Verify token is copied correctly (starts with `Token_`)
- Check for extra spaces or line breaks
- Ensure token hasn't been revoked in Ximilar dashboard
- Generate a new token if needed

### "No credits remaining" Error
- Check your usage at https://dashboard.ximilar.com/usage
- Wait for monthly reset (1st of each month)
- Upgrade to a paid plan if needed

### Low Confidence Scores (<80%)
- Improve lighting conditions
- Ensure card is in focus
- Try different angles
- Clean card surface if dirty/scuffed
- For slabs: ensure no glare on the plastic case

### Card Not Recognized
- Verify the game type is selected correctly (Pokemon vs One Piece)
- Check if the set is supported (very new sets may not be in database yet)
- Try manual entry for unsupported cards
- Report missing cards to Ximilar support for database updates

## Security Best Practices

### For Development
Current setup with hardcoded token is fine for testing.

### For Production (App Store Release)
You should migrate to secure storage:

1. **Use Keychain** for token storage
2. **Environment Variables** for build-time configuration
3. **Backend Proxy** for high-volume apps to hide your API key

Example Keychain implementation:
```swift
// Store token securely
KeychainManager.shared.save(token: "Token_...", for: "ximilar_api_token")

// Retrieve in CardRecognitionService
private lazy var apiToken: String = {
    KeychainManager.shared.retrieve(for: "ximilar_api_token") ?? ""
}()
```

### Rate Limiting
Ximilar has built-in rate limiting:
- **Free tier**: 10 requests/second
- **Paid tiers**: 50+ requests/second

CardShowPro already implements debouncing and queuing to stay within limits.

## Advanced Configuration

### Custom Endpoints
If you have custom Ximilar endpoints or private models:

```swift
private let customEndpoint = "https://api.ximilar.com/collectibles/v2/custom_model_id"
```

### Confidence Threshold
Adjust minimum confidence for auto-accept:

```swift
// In RecognitionResult.swift, line 17
var isReliable: Bool {
    confidence >= 0.75  // Lower = more cards auto-accepted, less accurate
}
```

### Batch Recognition
For scanning multiple cards rapidly, consider implementing batch endpoints:

```swift
func recognizeCards(images: [UIImage], game: CardGame) async throws -> [RecognitionResult]
```

## Support

### Ximilar Support
- **Email**: support@ximilar.com
- **Docs**: https://docs.ximilar.com
- **Status**: https://status.ximilar.com

### CardShowPro Support
- Check the codebase documentation
- Review error logs in Xcode console
- Test with mock data first (useRealAPI = false)

## Next Steps

1. ✅ Sign up for Ximilar account
2. ✅ Get API token
3. ✅ Configure CardRecognitionService.swift
4. ⏳ Test with real Pokemon cards
5. ⏳ Test with real One Piece cards
6. ⏳ Test with graded slabs (PSA/BGS/CGC)
7. ⏳ Monitor usage and upgrade plan if needed

Once testing is complete, you'll have a production-ready TCG scanning app with professional-grade accuracy!
