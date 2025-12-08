# TravelNurse App Monetization Guide

## Subscription Products

| Product ID | Price | Period | Free Trial |
|------------|-------|--------|------------|
| `com.travelnurse.premium.monthly` | $6.99 | Monthly | No |
| `com.travelnurse.premium.yearly` | $49.99 | Yearly | 7 days |

## Setup Checklist

### 1. Apple Developer Account
- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Accept latest agreements in App Store Connect

### 2. App Store Connect Setup
1. Create new app in App Store Connect
2. Go to **Features > In-App Purchases**
3. Click **+** and select **Auto-Renewable Subscription**
4. Create subscription group called "Premium"
5. Add both products:

**Monthly Premium:**
- Reference Name: Monthly Premium
- Product ID: `com.travelnurse.premium.monthly`
- Price: $6.99
- Duration: 1 Month

**Annual Premium:**
- Reference Name: Annual Premium
- Product ID: `com.travelnurse.premium.yearly`
- Price: $49.99
- Duration: 1 Year
- Free Trial: 7 Days

### 3. Testing Subscriptions

**In Xcode Simulator:**
1. Edit scheme > Run > Options
2. Set StoreKit Configuration to `StoreKitProducts.storekit`
3. Test purchases without Apple ID

**On Device (Sandbox):**
1. Create sandbox tester in App Store Connect
2. Sign out of App Store on device
3. Test app and sign in with sandbox account when prompted

### 4. Required App Store Metadata

**Screenshots needed:**
- 6.7" iPhone (1290 x 2796)
- 6.5" iPhone (1284 x 2778)
- 5.5" iPhone (1242 x 2208)
- iPad Pro 12.9" (2048 x 2732)

**App Description (suggested):**
```
TravelNurse - Your Complete Financial Companion

Built specifically for travel nurses, TravelNurse helps you:

✓ Track expenses & maximize tax deductions
✓ Log mileage automatically with GPS
✓ Maintain tax home compliance
✓ Store important documents securely
✓ Calculate quarterly estimated taxes

PREMIUM FEATURES:
★ AI Tax Assistant - Get instant answers to your tax questions
★ Quick Add - Add expenses using natural language
★ Smart Categorization - AI automatically categorizes expenses
★ Unlimited Document Storage
★ Advanced Tax Reports
★ Priority Support

Download now and take control of your travel nurse finances!
```

**Keywords (100 characters max):**
```
travel nurse,tax,expense tracker,mileage,per diem,stipend,1099,deductions,healthcare,nursing
```

### 5. Privacy Policy & Terms

Create these pages (required for subscriptions):
- Privacy Policy: `https://yourdomain.com/privacy`
- Terms of Service: `https://yourdomain.com/terms`

Update URLs in `PaywallView.swift`:
```swift
Link("Terms of Service", destination: URL(string: "https://yourdomain.com/terms")!)
Link("Privacy Policy", destination: URL(string: "https://yourdomain.com/privacy")!)
```

### 6. Submission Checklist

- [ ] All subscription products created in App Store Connect
- [ ] Subscription products are "Ready to Submit"
- [ ] Privacy policy URL added
- [ ] Terms of service URL added
- [ ] App icon (1024x1024)
- [ ] Screenshots for all required sizes
- [ ] App Store description completed
- [ ] Keywords optimized
- [ ] StoreKit configuration removed from release build
- [ ] Test all purchase flows

## Revenue Projections

**Conservative estimates:**

| Users | Conversion | Monthly Revenue |
|-------|------------|-----------------|
| 1,000 | 3% | $209/mo |
| 5,000 | 3% | $1,049/mo |
| 10,000 | 3% | $2,097/mo |
| 25,000 | 3% | $5,243/mo |

*Assumes 3% conversion rate, mix of monthly/annual subscribers*

## Marketing Ideas

1. **Content Marketing:**
   - Blog posts about travel nurse taxes
   - Tax season guides
   - Stipend comparison calculators

2. **Social Media:**
   - TikTok/Instagram showing app features
   - Facebook groups for travel nurses
   - LinkedIn articles for healthcare professionals

3. **Partnerships:**
   - Travel nurse agencies
   - Healthcare staffing companies
   - Nursing schools

4. **App Store Optimization:**
   - A/B test screenshots
   - Respond to all reviews
   - Regular updates with new features

## Support

For any issues with the subscription implementation, check:
1. Product IDs match exactly in App Store Connect
2. Agreements are signed in App Store Connect
3. Sandbox account is properly configured
4. App is using correct bundle identifier
