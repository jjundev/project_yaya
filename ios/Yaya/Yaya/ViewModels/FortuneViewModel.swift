import Foundation
import SwiftUI

@MainActor
final class FortuneViewModel: ObservableObject {
    @Published var dailyFortune: Fortune?
    @Published var weeklyFortune: Fortune?
    @Published var sajuAnalysis: SajuAnalysis?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let aiService = AIService.shared
    private let supabase = SupabaseService.shared

    /// 마지막으로 운세를 로드한 날짜 (자정 넘김 감지용)
    private var lastLoadedDate: String?

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

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

            // 캐시된 운세 확인 (테이블 미존재 등 에러 시 무시하고 AI 생성으로 진행)
            if let cached = try? await supabase.getFortune(userId: userId, type: .daily, date: Date()) {
                dailyFortune = cached
                lastLoadedDate = todayString
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

            // 캐시 저장 (테이블 미존재 시 무시)
            try? await supabase.saveFortune(fortune)
            dailyFortune = fortune
            lastLoadedDate = todayString
        } catch {
            errorMessage = "운세를 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - 주간 운세

    func loadWeeklyFortune(userId: UUID) async {
        do {
            // 캐시 확인 (테이블 미존재 등 에러 시 무시)
            if let cached = try? await supabase.getFortune(userId: userId, type: .weekly, date: Date()) {
                weeklyFortune = cached
                return
            }

            guard let saju = sajuAnalysis else { return }

            let content = try await aiService.generateFortune(
                sajuAnalysis: saju,
                type: .weekly,
                date: Date()
            )

            let fortune = Fortune(
                id: UUID(),
                userId: userId,
                fortuneType: .weekly,
                content: content,
                date: Date(),
                createdAt: Date()
            )

            try? await supabase.saveFortune(fortune)
            weeklyFortune = fortune
        } catch {
            // 주간 운세 로드 실패는 조용히 처리 (필수 아님)
        }
    }

    // MARK: - 날짜 변경 감지

    /// foreground 복귀 시 호출. 날짜가 바뀌었으면 true 반환.
    func hasDateChanged() -> Bool {
        return lastLoadedDate != nil && lastLoadedDate != todayString
    }
}
