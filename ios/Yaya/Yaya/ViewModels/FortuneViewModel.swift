import Foundation
import SwiftUI

@MainActor
final class FortuneViewModel: ObservableObject {
    @Published var dailyFortune: Fortune?
    @Published var sajuAnalysis: SajuAnalysis?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let aiService = AIService.shared
    private let supabase = SupabaseService.shared

    // MARK: - 사주 분석

    func loadSajuAnalysis(birthDate: Date, birthTime: BirthTime?, gender: Gender) async {
        isLoading = true
        defer { isLoading = false }

        do {
            errorMessage = nil
            sajuAnalysis = try await aiService.analyzeSaju(
                birthDate: birthDate,
                birthTime: birthTime,
                gender: gender
            )
        } catch {
            errorMessage = "사주 분석에 실패했습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - 오늘의 운세

    func loadDailyFortune(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            errorMessage = nil

            // 캐시된 운세 확인
            if let cached = try await supabase.getFortune(userId: userId, type: .daily, date: Date()) {
                dailyFortune = cached
                return
            }

            // 사주 분석이 없으면 먼저 로드
            guard let saju = sajuAnalysis else {
                errorMessage = "사주 분석을 먼저 진행해주세요"
                return
            }

            // AI로 새 운세 생성
            let content = try await aiService.generateFortune(
                sajuAnalysis: saju,
                type: .daily,
                date: Date()
            )

            let fortune = Fortune(
                id: UUID(),
                userId: userId,
                fortuneType: .daily,
                content: content,
                date: Date(),
                createdAt: Date()
            )

            // 캐시 저장
            try await supabase.saveFortune(fortune)
            dailyFortune = fortune
        } catch {
            errorMessage = "운세를 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }
}
