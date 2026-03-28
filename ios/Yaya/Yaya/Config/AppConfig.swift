import Foundation

enum AppConfig {
    // MARK: - Supabase
    static let supabaseURL = "https://hhhpjxhxiwgqyffaiwly.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhoaHBqeGh4aXdncXlmZmFpd2x5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NjExNDcsImV4cCI6MjA5MDEzNzE0N30.25m6LE3hQiOTTfbJ2-hN65zJQeQG4IZCXIF3gSvZt4g"
    static let redirectURL = "https://hhhpjxhxiwgqyffaiwly.supabase.co/auth/v1/callback"

    // MARK: - Kakao
    static let kakaoNativeAppKey = "dd9b4dd68e2d2c0a03d5bd8a16f46f2c"  // 카카오 개발자 콘솔 > 앱 설정 > 네이티브 앱 키

    // MARK: - Google
    static let googleClientID = "92080916081-ii8kbro7jkbposbte9b5lvsr7tpser2c.apps.googleusercontent.com"  // Google Cloud Console > OAuth 2.0 클라이언트 ID (iOS)

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

    // MARK: - Legal URLs
    static let termsOfServiceURL = URL(string: "https://yaya.app/terms")!
    static let privacyPolicyURL = URL(string: "https://yaya.app/privacy")!
}
