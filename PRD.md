# CardShow Pro - Product Requirements Document (PRD)

**Version:** 1.0
**Last Updated:** January 13, 2026
**Document Owner:** Product Team
**Status:** Active Development

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Problem Statement](#problem-statement)
3. [Product Vision & Mission](#product-vision--mission)
4. [Target Users & Personas](#target-users--personas)
5. [User Stories & Use Cases](#user-stories--use-cases)
6. [Core Value Proposition](#core-value-proposition)
7. [Feature Overview](#feature-overview)
8. [Business Model & Monetization](#business-model--monetization)
9. [Success Metrics & KPIs](#success-metrics--kpis)
10. [Competitive Analysis](#competitive-analysis)
11. [Release Strategy](#release-strategy)
12. [Constraints & Assumptions](#constraints--assumptions)
13. [Technical Requirements Summary](#technical-requirements-summary)
14. [Appendix & Related Documentation](#appendix--related-documentation)

---

## Executive Summary

**CardShow Pro** is a comprehensive mobile business management platform designed exclusively for trading card sellers. Unlike existing apps tailored to collectors, CardShow Pro provides vendor-focused tools for managing inventory, pricing, sales, trades, events, and customer relationships—all under one roof.

### Quick Facts

- **Platform:** iOS (iPhone/iPad)
- **Target Market:** Card sellers (vendors, online sellers, casual sellers)
- **Primary Card Game:** Pokemon TCG (V1), expanding to One Piece, Sports Cards, and other TCGs
- **Business Model:** Freemium + Subscription ($9.99/month)
- **Core Value:** All-in-one seller platform replacing 3+ separate tools
- **Launch Goal:** 10,000 users within 12 months

---

## Problem Statement

### The Problem

Card sellers currently cobble together multiple apps and tools to run their businesses:
- **Collectr** for inventory tracking (collector-focused, no business features)
- **eBay/TCGPlayer apps** for pricing lookups (slow, platform-specific)
- **Spreadsheets** for profit tracking and analytics
- **Pen & paper** for event management and customer info

**None of these tools are built for sellers.** They lack:
- Purchase cost tracking and profit calculations
- Platform fee calculators for online sales
- Trade analysis tools with custom percentages
- Event/vendor mode for card shows
- Customer relationship management
- Business analytics and reporting

### The Impact

Card sellers waste time:
- Switching between apps during negotiations
- Manually calculating profits after fees
- Tracking inventory across multiple systems
- Missing sales opportunities due to disorganized customer data
- Unable to analyze business performance effectively

### Who This Affects

Anyone making money from trading cards:
1. **Card Show Vendors** - Setting up tables at physical events
2. **Online Sellers** - eBay, TCGPlayer, Facebook Marketplace, Whatnot
3. **Casual Sellers** - Selling to friends, local trades, occasional deals

**All three segments need the same core tools:** inventory management, price checking, and profit tracking.

---

## Product Vision & Mission

### Vision Statement

> **CardShow Pro is the operating system for card businesses—empowering sellers of all sizes to run their entire operation from their phone with seller-first tools that collectors' apps ignore.**

### Mission

Build the first vendor-focused card business platform that:
- Eliminates the need for multiple apps and spreadsheets
- Provides real-time profit insights on every transaction
- Streamlines live event management with Vendor Mode
- Delivers actionable business analytics to drive growth
- Makes professional selling accessible to anyone in the card space

### Product Principles

1. **Seller-First Design** - Every feature solves a business problem, not a collector hobby need
2. **All-in-One Philosophy** - Reduce app clutter by providing comprehensive tools in one platform
3. **Speed & Efficiency** - Price lookups and calculations happen in seconds, not minutes
4. **Data-Driven Decisions** - Surface insights that help sellers buy smarter, sell faster, and grow revenue
5. **Professional Yet Accessible** - Premium tools that casual sellers can use, serious vendors can rely on

---

## Target Users & Personas

### Primary Persona: "Pro Vendor Victor"

**Background:**
- Age: 28-45
- Occupation: Full-time card vendor (or part-time with ambitions to go full-time)
- Experience: 2-5 years in card business
- Revenue: $50K-$200K annually from card sales

**Behaviors:**
- Attends 2-4 card shows per month
- Sells on eBay, TCGPlayer, and Whatnot
- Manages inventory of 1,000-5,000 cards
- Tracks everything in spreadsheets currently
- Values efficiency and profit margins above all else

**Needs:**
- Fast price lookups during live negotiations
- Profit tracking on every card (purchase cost → market value → sale price)
- Event management tools for card shows
- Sales analytics to identify best-performing inventory
- Customer relationship tracking for repeat business

**Pain Points:**
- Juggling 3+ apps during transactions is slow and unprofessional
- No way to calculate net profit after platform fees without a calculator
- Loses track of customer want lists and misses sales opportunities
- Can't analyze which shows or platforms are most profitable

**Success Metric:** Victor subscribes if CardShow Pro saves him 5+ hours per week and increases profits by 10%+.

---

### Secondary Persona: "Online Seller Olivia"

**Background:**
- Age: 22-35
- Occupation: Side hustle (student, part-time job, or stay-at-home parent)
- Experience: 6 months - 2 years selling cards
- Revenue: $10K-$40K annually

**Behaviors:**
- Sells primarily on eBay and Facebook Marketplace
- Sources cards from Target/Walmart pack openings, local trades
- Manages inventory of 200-800 cards
- Uses notes app and memory to track cards
- Focuses on high-margin flips

**Needs:**
- Quick price lookups when sourcing cards at retail stores
- Sales calculator to know if listing fees are worth it
- Simple inventory to track what she owns
- Trade analyzer to evaluate deals on social media

**Pain Points:**
- Doesn't know if eBay fees make low-value cards worth selling
- Hard to remember which cards are in inventory when someone messages on Facebook
- No way to track profit margins over time

**Success Metric:** Olivia subscribes if CardShow Pro helps her avoid bad deals and simplifies inventory tracking.

---

### Tertiary Persona: "Casual Seller Chris"

**Background:**
- Age: 18-30
- Occupation: Hobbyist who occasionally sells
- Experience: New to selling (0-1 year)
- Revenue: $2K-$10K annually

**Behaviors:**
- Opens packs for fun, sells hits
- Trades with friends and at local game stores
- No formal inventory system
- Uses price lookup apps occasionally

**Needs:**
- Free price lookup tool
- Basic inventory to track personal collection + business cards
- Trade fairness calculator

**Pain Points:**
- Gets taken advantage of in trades due to lack of pricing knowledge
- Doesn't know if cards are worth selling or keeping

**Success Metric:** Chris uses free tier and upgrades when he gets serious about selling.

---

## User Stories & Use Cases

### Epic 1: Price Lookup & Valuation

**User Story 1.1: Instant Price Lookup**
> As a vendor, I need to look up card prices in seconds so I can quote buyers or evaluate purchases on the spot.

**Acceptance Criteria:**
- Search by card name, set, and number
- Display market price, low, mid, high from TCGPlayer
- Show all variants (Normal, Holo, Reverse Holo, etc.)
- Results appear in <2 seconds
- Works offline with cached data

**Use Case:**
- Victor is at a card show. A customer asks "How much for this Charizard?"
- Victor opens CardShow Pro → Price Lookup
- Types "Charizard" → selects set → sees $180 market price
- Quotes customer $200 → closes sale in 30 seconds

---

**User Story 1.2: Condition-Based Pricing**
> As a seller, I need to see prices for different card conditions so I can price damaged or graded cards accurately.

**Acceptance Criteria:**
- Display prices for Near Mint, Lightly Played, Moderately Played, Heavily Played
- Show PSA/BGS graded card prices when available
- Allow manual condition selection in price lookup

---

### Epic 2: Inventory Management

**User Story 2.1: Business Inventory Tracking**
> As a seller, I need to track every card's purchase cost, current market value, and profit margin so I know which inventory is most profitable.

**Acceptance Criteria:**
- Add cards manually or from price lookup
- Record: Card name, set, number, variant, condition, purchase cost, purchase source, date acquired
- Auto-fetch current market price from API
- Calculate: Profit margin (market value - purchase cost), ROI %
- Display total inventory value and total potential profit

**Use Case:**
- Olivia buys 10 Pikachu cards from a trade for $50 total ($5 each)
- She adds them to inventory with $5 purchase cost
- App shows market value is $8 each → $3 profit margin per card
- Dashboard shows total inventory value increased by $80, profit potential up $30

---

**User Story 2.2: Personal Collection Tracking**
> As a seller who also collects, I need to separate my personal collection from business inventory so I don't accidentally sell cards I want to keep.

**Acceptance Criteria:**
- Toggle between "Business Inventory" and "Personal Collection"
- Personal collection tracks: Card info, current market value (no purchase cost or profit)
- Personal cards don't appear in vendor mode or sales features
- Same card database for both

---

**User Story 2.3: Inventory Search & Filtering**
> As a vendor with 1,000+ cards, I need to quickly find specific cards or filter by value/condition so I can respond to customer requests.

**Acceptance Criteria:**
- Search by card name, set, number
- Filter by: Value range, card type, condition, date acquired, profit margin
- Sort by: Name, value, date, profit margin
- Results update in real-time

---

### Epic 3: Trade Analyzer

**User Story 3.1: Trade Fairness Calculator**
> As a seller, I need to calculate trade values with custom percentages so I maintain my profit margin when trading cards.

**Acceptance Criteria:**
- Add cards to "My Side" and "Their Side"
- Set custom trade percentage (default 80%, adjustable 50-100%)
- Calculate:
  - Their cards incoming at X% of market value
  - My cards outgoing at 100% of market value
  - Trade differential (who owes more)
- Save trade percentage presets (80% liquid cards, 70% slow movers, 90% high-demand)

**Use Case:**
- Victor evaluates a trade: Customer offers $100 Charizard for Victor's cards
- Victor sets 80% trade percentage (standard business rate)
- Customer's Charizard valued at $80 trade value
- Victor adds $80 worth of his cards (at market price)
- Trade balanced → Victor accepts

---

**User Story 3.2: Trade History & Record Keeping**
> As a seller, I need to track completed trades so I can review past deals and maintain transaction records.

**Acceptance Criteria:**
- Save completed trades with: Date, cards exchanged, values, trade percentage used
- Cards traded away are removed from inventory
- Cards traded in go through onboarding flow (assign purchase cost = trade value)
- Trade history accessible in analytics

---

### Epic 4: Sales Calculator

**User Story 4.1: Platform Fee Calculator**
> As an online seller, I need to calculate net profit after platform fees and shipping so I know if a sale is worth listing.

**Acceptance Criteria:**
- Built-in presets for: eBay, TCGPlayer, Whatnot (customizable)
- Input: Sale price
- Calculate: Platform fees, payment processing fees, shipping cost, supplies cost
- Output: Net profit, profit margin %
- Compare multiple platforms side-by-side

**Use Case:**
- Olivia has a $50 card. Should she sell on eBay or TCGPlayer?
- Opens Sales Calculator
- eBay: $50 - 12.9% fee - $1 shipping - $0.50 supplies = $36.10 net
- TCGPlayer: $50 - 10% fee - $0.50 supplies = $44.50 net
- TCGPlayer is better → lists there

---

**User Story 4.2: Custom Fee Profiles**
> As a seller, I need to save my actual fee rates because I have different seller levels on each platform.

**Acceptance Criteria:**
- Edit platform fee percentages
- Save custom profiles (e.g., "eBay Top Rated Seller" with lower fees)
- Set default shipping/supplies costs per platform

---

### Epic 5: Vendor Mode (Event Management)

**User Story 5.1: Event Scheduling & Setup**
> As a card show vendor, I need to prepare for upcoming shows by scheduling events and curating inventory so I'm organized on show day.

**Acceptance Criteria:**
- Create event: Name, date, location, table number, notes
- Curate inventory: Move cards from main inventory into event categories
  - "Display Case" - High-value cards in locked case
  - "Binder" - Mid-value cards in binders
  - "Bulk Boxes" - Low-value cards in boxes
- Pre-event inventory shows: Total cards, total value, expected revenue

**Use Case:**
- Victor has a show on Saturday
- Creates "Phoenix Card Show - Jan 20" event
- Selects 200 high-value cards → assigns to "Display Case"
- Selects 500 mid-value cards → assigns to "Binder"
- App shows: Bringing $15,000 worth of inventory

---

**User Story 5.2: Live Sales & Trade Tracking**
> As a vendor during a show, I need to record sales and trades in real-time so inventory stays accurate and I know how the day is going.

**Acceptance Criteria:**
- Quick-add sales: Select card, enter sale price, mark sold
- Quick-add trades: Use Trade Analyzer, complete → updates inventory
- Running totals: Sales revenue, profit, cards sold
- Inventory updates live (cards disappear when sold)

---

**User Story 5.3: Multi-User Collaboration**
> As a vendor with employees, I need multiple people to record sales simultaneously so we don't lose track of transactions.

**Acceptance Criteria:**
- Event creator generates access code
- Other users enter code → join event session
- All sales/trades sync to main account in real-time
- Each transaction tagged with: Who made sale, timestamp, amount
- Main account sees all activity live

**Use Case:**
- Victor and his two employees work a show
- Victor creates event → shares access code "XYZ123"
- Employees join session on their phones
- Employee A sells $300 worth of cards
- Employee B makes a trade
- Victor's phone shows all transactions in real-time

---

**User Story 5.4: Post-Event Analytics**
> As a vendor, I need a comprehensive show report after the event so I can evaluate performance and improve future shows.

**Acceptance Criteria:**
- End event session → generate report
- Show metrics:
  - Total revenue
  - Total profit (revenue - cost basis of cards sold)
  - Cards sold vs. cards brought
  - Average sale price
  - Employee performance (if multi-user)
  - Customer count (if tracked)
- Save to event history for comparison
- Export report as PDF

---

### Epic 6: Contact & CRM System

**User Story 6.1: Customer Profiles**
> As a seller, I need to track customer information and purchase history so I can build relationships and repeat business.

**Acceptance Criteria:**
- Add contact: Name, phone, email, role (Customer/Distributor/Vendor)
- Auto-tag with: Where met (event name, online platform)
- View purchase history: What they bought, when, how much
- Add notes: "Loves Charizards, will pay premium"

---

**User Story 6.2: Customer Want Lists**
> As a seller, I need to track what customers are looking for so I can notify them when I get cards they want.

**Acceptance Criteria:**
- Add cards to customer want list
- Set priority: High/Medium/Low
- Set max price customer will pay
- View all want lists in one place

---

**User Story 6.3: Smart Inventory Alerts**
> As a seller, I need automatic notifications when I acquire a card a customer wants so I don't miss sales opportunities.

**Acceptance Criteria:**
- When card added to inventory → check all customer want lists
- If match found → push notification: "Customer John wants this Charizard!"
- Tap notification → open customer profile with contact info
- Mark notification as "Contacted" or "Sold"

**Use Case:**
- Victor adds Charizard to inventory
- App alerts: "Customer Sarah wants Charizard (max $150)"
- Victor texts Sarah → sells for $145
- Updates contact: Sale recorded, removes from want list

---

### Epic 7: Analytics Dashboard

**User Story 7.1: Business Intelligence Overview**
> As a seller, I need comprehensive analytics so I can make data-driven decisions about my business.

**Acceptance Criteria:**
- Display metrics:
  - Total inventory value
  - Total potential profit
  - Lifetime sales revenue
  - Lifetime profit
  - Monthly revenue trend (chart)
  - Top 10 best-selling cards
  - Top 10 most profitable cards
  - Inventory turnover rate
  - Average profit margin %
- Filter by date range (last 7 days, 30 days, 90 days, year, all time)
- Export data as CSV or PDF

---

**User Story 7.2: Event Performance Comparison**
> As a vendor, I need to compare show performance so I know which events to attend and which to skip.

**Acceptance Criteria:**
- List all past events with: Date, location, revenue, profit, cards sold
- Sort by profitability
- Chart: Revenue by event over time
- Calculate: Average revenue per show, best/worst performing shows

---

**User Story 7.3: Platform Performance Analysis**
> As an online seller, I need to see which platforms generate the most profit so I can focus my efforts.

**Acceptance Criteria:**
- Track sales by platform (eBay, TCGPlayer, Whatnot, In-Person, etc.)
- Display: Revenue, profit, fees paid, net profit by platform
- Chart: Platform comparison (which is most profitable after fees)

---

### Epic 8: Grading Management

**User Story 8.1: Grading Submission Tracking**
> As a seller who submits cards for grading, I need to track cards out for grading so I know what's where and when to expect returns.

**Acceptance Criteria:**
- Mark card as "Submitted for Grading"
- Record: Grading company (PSA/BGS/CGC), submission date, service level, cost
- Card moves to "Out for Grading" inventory status
- Track turnaround time (days since submission)
- Receive notification when expected return date approaches

---

**User Story 8.2: Grading ROI Calculator**
> As a seller, I need to calculate grading ROI so I know which raw cards are worth sending to grading.

**Acceptance Criteria:**
- Input: Raw card current value, expected grade (PSA 8/9/10)
- Display: Graded card market value by grade
- Calculate: Grading cost + shipping → Net ROI
- Recommendation: "Worth grading" or "Not worth it"

**Use Case:**
- Victor has raw Charizard worth $50
- Grading ROI Calculator shows:
  - PSA 8: $100 value - $30 grading cost = $70 ($20 profit)
  - PSA 9: $200 value - $30 grading cost = $170 ($120 profit)
  - PSA 10: $500 value - $30 grading cost = $470 ($420 profit)
- Victor sends for grading → hopes for PSA 9+

---

### Epic 9: AI-Powered Features

**User Story 9.1: Card Analyzer (AI Grading Assistant)**
> As a seller, I need AI to suggest card grades so I can make informed grading decisions.

**Acceptance Criteria:**
- Take photo of card (front and back)
- AI analyzes: Centering, edges, corners, surface
- Provide alignment guides for proper photo
- Suggest likely grade: PSA 7, 8, 9, or 10
- Confidence score (e.g., "70% confident this is PSA 9")
- Highlight defects if detected

---

**User Story 9.2: Pro Market Agent (AI Market Insights)**
> As a seller, I need AI-powered market insights so I know when to buy, sell, or hold inventory.

**Acceptance Criteria:**
- Daily/weekly market reports:
  - "Charizard prices up 15% this week - good time to sell"
  - "Japanese sets trending down - hold off buying"
  - "Top 10 trending cards this week"
- Price alerts: Notify when watched cards hit target prices
- Historical price charts with trend analysis
- Seasonal insights: "Prices historically spike in December"

---

**User Story 9.3: Listing Generator (AI Copywriting)**
> As an online seller, I need AI to write compelling listings so I can save time and improve conversions.

**Acceptance Criteria:**
- Input: Card (photo or select from inventory)
- Select platform: eBay, TCGPlayer, Whatnot, Facebook
- AI generates:
  - SEO-optimized title
  - Compelling description highlighting card features
  - Suggested competitive price (based on recent comps)
- Platform-specific optimization (eBay listings differ from TCGPlayer)
- Edit AI-generated text before publishing

**Use Case:**
- Olivia wants to list Pikachu on eBay
- Selects card from inventory → chooses "eBay"
- AI generates:
  - Title: "Pokemon Pikachu VMAX 044/185 Vivid Voltage Holo Rare NM"
  - Description: "Beautiful Near Mint Pikachu VMAX from Vivid Voltage set. Card has sharp corners, excellent centering, and vibrant holo. Perfect for collectors or competitive players. Ships securely in penny sleeve + toploader within 24 hours!"
  - Suggested price: $12.99 (based on recent sold listings)
- Olivia copies to eBay → lists in 60 seconds

---

### Epic 10: Utility Tools

**User Story 10.1: Digital Magnifier**
> As a seller, I need a digital magnifier to inspect card condition quickly and show customers close-ups.

**Acceptance Criteria:**
- Opens camera in macro mode
- Flashlight toggle with brightness slider
- Tap screen → freeze frame
- Hold tap → image stays frozen
- Release tap → unfreezes
- Save frozen images to gallery

**Use Case:**
- Customer asks "Are there any scratches on the holo?"
- Victor opens Digital Magnifier
- Zooms in on holo foil → taps to freeze
- Shows customer screen: "See? Perfectly clean."
- Customer satisfied → buys card

---

---

## Core Value Proposition

### What Makes CardShow Pro Different?

**For Vendors:**
> "The only app built for card sellers, not collectors. Manage your entire business from your phone—inventory, pricing, events, customers, and analytics—all in one place."

**For Online Sellers:**
> "Stop juggling spreadsheets and calculator apps. Know your profit on every deal instantly and list smarter with AI-powered tools."

**For Casual Sellers:**
> "Never get ripped off in trades again. Free price lookup and trade calculator keep you informed and profitable."

### The Competitive Moat

1. **Seller-First Feature Set** - No competitor addresses vendor mode, trade percentages, or platform fee calculators
2. **All-in-One Efficiency** - Replaces Collectr + TCGPlayer App + Spreadsheets + Calculator
3. **Business Analytics** - Real profit tracking (not just collection value)
4. **AI Integration** - Market insights, grading assistance, listing optimization
5. **Event Management** - Built specifically for live card show workflows

---

## Feature Overview

### V1 Launch (MVP) - Q2 2026

**Core Features (Must-Have):**
1. ✅ **Price Lookup** - Fast, accurate TCGPlayer pricing with variant support
2. ✅ **Business Inventory Management** - Purchase cost, profit margins, full tracking
3. ✅ **Vendor Mode** - Event scheduling, inventory curation, live sales tracking, post-event analytics
4. ✅ **Analytics Dashboard** - Revenue, profit, inventory value, trends

**Supporting Features:**
5. Personal Collection (separate from business inventory)
6. Basic search/filter/sort for inventory
7. Manual card entry workflow

**Free Tier:**
- Price Lookup (unlimited)
- Basic Inventory (100 card limit)

**Paid Tier ($9.99/month):**
- Everything in Free +
- Unlimited inventory
- Vendor Mode
- Analytics Dashboard
- Personal Collection

---

### V2 Release - Q3 2026

**Business Tools:**
1. **Trade Analyzer** - Custom percentages, trade history, inventory integration
2. **Sales Calculator** - Platform fee calculator with presets (eBay, TCGPlayer, Whatnot)
3. **Contact/CRM System** - Customer profiles, purchase history, want lists, smart alerts

**Advanced Features:**
4. **Grading Management** - Submission tracking, ROI calculator, turnaround monitoring
5. **Multi-platform support** - Expand beyond Pokemon (One Piece TCG, Sports Cards)

---

### V3 Release - Q4 2026

**AI-Powered Features:**
1. **Card Analyzer** - AI grading suggestions, centering analysis, defect detection
2. **Pro Market Agent** - Market insights, price alerts, trending cards, seasonal analysis
3. **Listing Generator** - AI copywriting for eBay, TCGPlayer, platform-optimized listings

**Utility Tools:**
4. **Digital Magnifier** - Macro mode, freeze-frame, brightness control

---

### Future Considerations (V4+)

- Bulk import (CSV, spreadsheet)
- Barcode/QR code scanning
- Integration with eBay/TCGPlayer APIs (auto-list from app)
- Team management (roles, permissions, payroll)
- Multi-language support
- Web dashboard (companion to mobile app)
- Advanced reporting (tax export, profit/loss statements)

---

## Business Model & Monetization

### Pricing Strategy

**Freemium Model:**
- Free Tier: Price Lookup + Basic Inventory (100 cards max)
- Paid Tier: $9.99/month (all features, unlimited inventory)

**Free Trial:**
- 14-day full access trial (all paid features unlocked)
- No credit card required to start trial
- Prompted to subscribe on day 12

### Rationale

**Why Freemium?**
- Lowers barrier to entry for casual sellers
- Free tier drives word-of-mouth growth
- Users upgrade naturally as they grow their business
- Price Lookup is a gateway drug to paid features

**Why $9.99/month?**
- Comparable to Netflix/Spotify (familiar pricing)
- Low enough for casual sellers to justify
- High enough to be sustainable (target: 10,000 paid users = $100K MRR)
- Positioned below business software ($20-50/month) but above consumer apps ($3-5/month)

### Revenue Projections (Year 1)

| Month | Free Users | Paid Users | MRR | ARR |
|-------|-----------|-----------|-----|-----|
| Month 3 (Launch) | 500 | 50 | $500 | $6,000 |
| Month 6 | 2,000 | 200 | $2,000 | $24,000 |
| Month 12 | 8,000 | 1,000 | $10,000 | $120,000 |

**Assumptions:**
- 10-15% free-to-paid conversion rate
- 20% monthly user growth (organic + word-of-mouth)
- 5% monthly churn (low due to sticky business tool nature)

### Future Monetization Opportunities

1. **Premium Tier** ($19.99/month) - Advanced features (team management, API integrations, white-label reports)
2. **One-Time Add-Ons** - Export tools, bulk import, historical data migration
3. **Affiliate Revenue** - Referral fees from grading companies (PSA/BGS), card supplies vendors
4. **Advertising (Free Tier Only)** - Non-intrusive banner ads for card shows, grading services

---

## Success Metrics & KPIs

### North Star Metric

**Active Paid Subscribers** - The single metric that captures product value and business health.

### Primary KPIs

| Metric | Target (Month 12) | Why It Matters |
|--------|----------|----------------|
| **Total Users** | 10,000 | Market penetration |
| **Paid Subscribers** | 1,000 | Revenue sustainability |
| **Free-to-Paid Conversion** | 10-15% | Product value validation |
| **Monthly Churn Rate** | <5% | Retention/stickiness |
| **Monthly Recurring Revenue (MRR)** | $10,000 | Business viability |
| **Daily Active Users (DAU)** | 2,500 | Engagement health |

### Product Engagement Metrics

| Feature | Success Metric |
|---------|---------------|
| **Price Lookup** | >50 lookups per user per month |
| **Inventory** | >100 cards added per paid user |
| **Vendor Mode** | >2 events scheduled per user per month |
| **Trade Analyzer** | >5 trades evaluated per user per month |
| **Analytics Dashboard** | Viewed >4 times per month per user |

### User Satisfaction Metrics

- **Net Promoter Score (NPS):** Target 50+ (measure quarterly)
- **App Store Rating:** Target 4.5+ stars
- **Feature Request Voting:** Track top 10 requested features monthly
- **Support Ticket Volume:** <2% of users per month (indicates low friction)

### Business Impact Metrics (User Self-Reported)

Survey paid users quarterly:
- "How much time does CardShow Pro save you per week?" (Target: 5+ hours)
- "Has CardShow Pro increased your profits?" (Target: 70% say yes)
- "Would you recommend CardShow Pro to other sellers?" (Target: 80% yes)

---

## Competitive Analysis

### Current Market Landscape

| Competitor | Type | Target User | Key Features | Pricing | Weaknesses |
|-----------|------|-------------|--------------|---------|------------|
| **Collectr** | Inventory App | Collectors | Collection tracking, value estimates | $4.99/month | No business features (profit, sales, events) |
| **TCGPlayer App** | Marketplace | Buyers/Sellers | Price lookup, online marketplace | Free | Only for TCGPlayer platform, no inventory |
| **eBay App** | Marketplace | General sellers | Listings, sales | Free (fees on sales) | Not card-specific, no inventory management |
| **Card Ladder** | Market Data | Investors | Price trends, population reports | $9.99/month | Read-only data, no selling tools |
| **Excel/Google Sheets** | Spreadsheet | DIY sellers | Custom tracking | Free | Manual, time-consuming, not mobile-friendly |

### Competitive Positioning

**CardShow Pro vs. Collectr:**
- Collectr = "Track your collection's value"
- CardShow Pro = "Run your card business"
- **Differentiation:** Business-focused features (profit tracking, vendor mode, sales calculator, CRM)

**CardShow Pro vs. TCGPlayer/eBay Apps:**
- They = "Sell on OUR platform"
- CardShow Pro = "Sell anywhere, manage everything"
- **Differentiation:** Platform-agnostic, comprehensive business tools

**CardShow Pro vs. Spreadsheets:**
- Spreadsheets = "DIY manual tracking"
- CardShow Pro = "Automated, mobile-first, AI-powered"
- **Differentiation:** Speed, automation, insights, accessibility

### Unique Selling Points (USPs)

1. **Only vendor-focused card app** - No competitor addresses live event management
2. **All-in-one platform** - Replaces 3+ tools with single app
3. **Profit-first design** - Every feature calculates real business profit, not collection value
4. **AI integration** - Market insights, grading assistance, listing generation (future)
5. **Mobile-native** - Built for on-the-go sellers, not desktop collectors

### Barriers to Entry (Moat)

1. **Data Network Effects** - More users → better market insights → attracts more users
2. **Switching Costs** - Once inventory is in CardShow Pro, migrating out is painful
3. **Feature Depth** - Comprehensive tool suite is hard to replicate quickly
4. **Seller Trust** - First-mover advantage in vendor community builds brand loyalty

---

## Release Strategy

### V1 Launch (MVP) - Target: Q2 2026

**Scope:**
- Price Lookup
- Business Inventory
- Vendor Mode
- Analytics Dashboard
- Personal Collection

**Launch Plan:**
1. **Private Beta** (50 vendors) - March 2026
   - Invite Pro Vendor Victor types from local card shows
   - Gather feedback, fix critical bugs
   - Refine onboarding flow

2. **Public Beta** (500 users) - April 2026
   - Soft launch on App Store (no marketing)
   - Post in card seller Facebook groups for beta testers
   - Iterate based on feedback

3. **V1 Official Launch** - May 2026
   - Full App Store launch with marketing
   - Press release to card industry publications
   - Launch discount: First 1,000 users get 50% off first 3 months
   - Target: 1,000 total users by end of May

**Success Criteria:**
- 100 paid subscribers within 30 days
- 4.0+ App Store rating
- <10% churn rate
- NPS score 40+

---

### V2 Release - Target: Q3 2026

**Scope:**
- Trade Analyzer
- Sales Calculator
- Contact/CRM System
- Grading Management
- Expand to One Piece TCG

**Launch Plan:**
- Announce V2 roadmap to existing users (build anticipation)
- Invite beta testers from paid subscriber base
- Feature-by-feature rollout (not all at once)
- Case studies: "How vendor X increased profits 20% with Trade Analyzer"

**Success Criteria:**
- 5,000 total users
- 500 paid subscribers
- 15% free-to-paid conversion
- Feature adoption: 50% of paid users use Trade Analyzer monthly

---

### V3 Release - Target: Q4 2026

**Scope:**
- AI-powered features (Card Analyzer, Pro Market Agent, Listing Generator)
- Digital Magnifier
- Expand to Sports Cards

**Launch Plan:**
- Position as "AI upgrade" - premium tier consideration
- Marketing focus: "CardShow Pro gets smarter"
- Influencer partnerships (card YouTubers test AI features)

**Success Criteria:**
- 10,000 total users
- 1,000 paid subscribers
- $10K MRR

---

### Post-V3 Roadmap

**2027 Focus:**
- Platform integrations (eBay API, TCGPlayer API for auto-listing)
- Team/multi-user features (employee roles, permissions)
- Web dashboard (desktop companion app)
- International expansion (multi-language support)

---

## Constraints & Assumptions

### Technical Constraints

1. **iOS-Only (V1)** - No Android until proven product-market fit
2. **API Dependencies** - Relies on PokemonTCG.io (free), TCGPlayer API (may require partnership), eBay API
3. **Offline Functionality** - Limited offline mode (price lookups require internet)
4. **Data Storage** - SwiftData (on-device) - future cloud sync requires backend infrastructure
5. **AI Features** - Require third-party APIs (OpenAI, custom ML models) - cost implications

### Business Assumptions

1. **Target Market Size** - Estimated 50,000+ active card sellers in US (Pokemon + sports + other TCGs)
2. **Willingness to Pay** - Vendors currently spend $20-50/month on tools (spreadsheets, apps, supplies) → willing to consolidate to $9.99
3. **Word-of-Mouth Growth** - Card community is tight-knit → viral potential if product solves real problems
4. **Low Churn** - Business tools are sticky (switching costs high once inventory is populated)
5. **Freemium Conversion** - 10-15% free-to-paid based on similar business app benchmarks

### Risks & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|------------|-----------|
| **API Changes/Costs** | High | Medium | Diversify API providers, build partnerships, cache data |
| **Competitor Copycat** | Medium | High | Rapid feature development, build community moat |
| **Low Adoption** | High | Low | Beta testing validates demand, pivot if needed |
| **Technical Debt** | Medium | Medium | Follow best practices (see ARCHITECTURE.md), regular refactoring |
| **Platform Risk (iOS)** | Medium | Low | Plan Android version for 2027 |

### Key Assumptions to Validate

1. **Vendors will pay $9.99/month** - Validate with beta pricing tests
2. **Vendor Mode drives subscriptions** - Track conversion after first event use
3. **AI features justify premium positioning** - A/B test AI vs. non-AI workflows
4. **Multi-card-game support expands market** - Track demand for One Piece, sports in user surveys

---

## Technical Requirements Summary

### Platform & Infrastructure

- **Platform:** iOS 17.0+ (iPhone and iPad)
- **Language:** Swift 6.1+
- **UI Framework:** SwiftUI
- **Architecture:** MV (Model-View) pattern with @Observable
- **Concurrency:** Swift Concurrency (async/await)
- **Testing:** Swift Testing framework
- **Persistence:** SwiftData (on-device storage)
- **Networking:** URLSession (async/await)

### External Integrations

| API | Purpose | Status | Cost |
|-----|---------|--------|------|
| **PokemonTCG.io** | Pokemon card data, images | Active | Free |
| **TCGPlayer API** | Pricing data (all TCGs) | Planned | TBD (partnership needed) |
| **eBay API** | Sold listings, market data | Planned | Free tier available |
| **OpenAI API** | AI features (grading, insights, listing gen) | Planned | Pay-per-token |

### Performance Requirements

- **Price Lookup:** <2 seconds from search to results
- **Inventory Sync:** Real-time updates in Vendor Mode (<1 second latency)
- **App Launch:** <3 seconds cold start
- **Offline Mode:** Basic inventory browsing and cached price lookups

### Security & Privacy

- **Data Encryption:** All user data encrypted at rest (SwiftData default)
- **API Keys:** Stored securely in Keychain
- **Privacy Policy:** Compliant with App Store requirements
- **GDPR/CCPA:** Data export and deletion capabilities
- **No Third-Party Analytics:** Privacy-first approach (no Firebase, Mixpanel, etc. in V1)

### Accessibility

- VoiceOver support for all core features
- Dynamic Type support
- High contrast mode compatibility
- Target: WCAG 2.1 AA compliance

---

## Appendix & Related Documentation

### Technical Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture, design patterns, data flow
- **[DEVELOPMENT.md](./DEVELOPMENT.md)** - Development workflows, coding standards
- **[CLAUDE.md](./CLAUDE.md)** - AI coding assistant rules and guidelines
- **[FEATURES.json](./ai/FEATURES.json)** - Granular feature acceptance criteria and status
- **[PROGRESS.md](./ai/PROGRESS.md)** - Development session history and decisions

### Planned Documentation (In Progress)

- **API_DOCUMENTATION.md** - External API integration guide
- **TESTING_STRATEGY.md** - QA and test coverage plan
- **DATA_MODEL.md** - SwiftData schema and database design
- **DEPLOYMENT.md** - App Store submission and release process
- **SECURITY.md** - Security best practices and compliance
- **USER_GUIDE.md** - End-user documentation and tutorials
- **TROUBLESHOOTING.md** - Common issues and solutions
- **RELEASE_CHECKLIST.md** - Pre-release verification steps

### Glossary

- **Vendor:** Card seller who sets up tables at physical card shows/events
- **Vendor Mode:** CardShow Pro feature for managing live selling events
- **Liquid Cards:** High-demand cards that sell quickly (e.g., Charizard, popular graded cards)
- **Trade Percentage:** The discount percentage applied when accepting cards in trade (e.g., 80% = accept $100 card as $80 trade value)
- **Grading:** Professional authentication and condition assessment by companies like PSA, BGS, CGC
- **Raw Card:** Ungraded card in original condition
- **Comps:** Comparable sales (recent sold listings used to determine pricing)
- **ROI:** Return on Investment
- **NM/LP/MP/HP:** Card conditions (Near Mint, Lightly Played, Moderately Played, Heavily Played)

---

## Document Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Jan 13, 2026 | Product Team | Initial PRD created from founder interview |

---

**Next Steps:**
1. Review and validate PRD with stakeholders
2. Prioritize V1 features in FEATURES.json
3. Begin development sprint planning
4. Set up beta tester recruitment
5. Create API partnership outreach plan (TCGPlayer)

---

*This document is a living artifact and will be updated as the product evolves. For questions or feedback, contact the product team.*
