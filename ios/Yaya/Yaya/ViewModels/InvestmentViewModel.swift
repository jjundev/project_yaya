import Foundation
import SwiftUI

@MainActor
final class InvestmentViewModel: ObservableObject {
    @Published var investmentProfile: InvestmentProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let aiService = AIService.shared
    private let supabase = SupabaseService.shared

    // MARK: - 투자 성향 분석

    func loadInvestmentProfile(userId: UUID, sajuAnalysis: SajuAnalysis) async {
        isLoading = true
        defer { isLoading = false }

        do {
            errorMessage = nil

            // 캐시된 프로필 확인
            if let cached = try await supabase.getInvestmentProfile(userId: userId) {
                investmentProfile = cached
                return
            }

            // AI로 투자 성향 분석
            let profile = try await aiService.analyzeInvestmentType(sajuAnalysis: sajuAnalysis)

            // 저장
            try await supabase.saveInvestmentProfile(profile)
            investmentProfile = profile
        } catch {
            errorMessage = "투자 성향 분석에 실패했습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - 복리 계산기

    func calculateCompoundInterest(
        principal: Double,
        annualRate: Double,
        years: Int,
        taxRate: Double = 0.22
    ) -> CompoundResult {
        let grossAmount = principal * pow(1 + annualRate, Double(years))
        let profit = grossAmount - principal
        let tax = profit * taxRate
        let netAmount = grossAmount - tax

        return CompoundResult(
            principal: principal,
            grossAmount: grossAmount,
            profit: profit,
            tax: tax,
            netAmount: netAmount,
            years: years
        )
    }
}

struct CompoundResult {
    let principal: Double
    let grossAmount: Double
    let profit: Double
    let tax: Double
    let netAmount: Double
    let years: Int

    var formattedNetAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: netAmount)) ?? "0") + "원"
    }
}
