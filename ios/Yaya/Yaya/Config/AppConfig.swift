import Foundation

enum AppConfig {
    // MARK: - Supabase
    static let supabaseURL = "https://YOUR_PROJECT.supabase.co"
    static let supabaseAnonKey = "YOUR_ANON_KEY"

    // MARK: - AI API
    static let aiAPIKey = "YOUR_AI_API_KEY"
    static let aiBaseURL = "https://api.anthropic.com/v1"

    // MARK: - App Settings
    static let referralRequiredCount = 2
    static let couponAmountWon = 3000
    static let couponIntervalDays = 14
    static let freeTrialDays = 7

    // MARK: - Subscription Prices (KRW)
    static let basicMonthlyPrice = 4900
    static let standardMonthlyPrice = 9900
    static let premiumMonthlyPrice = 19000

    // MARK: - Product IDs (App Store Connect)
    static let basicProductID = "com.yaya.subscription.basic"
    static let standardProductID = "com.yaya.subscription.standard"
    static let premiumProductID = "com.yaya.subscription.premium"
}
