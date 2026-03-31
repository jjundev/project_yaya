import SwiftUI

struct FortuneDetailView: View {
    @EnvironmentObject var fortuneVM: FortuneViewModel

    var body: some View {
        Group {
            if let fortune = fortuneVM.dailyFortune {
                contentView(fortune.content)
            } else {
                emptyStateView
            }
        }
        .navigationTitle("오늘의 운세")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Content

    private func contentView(_ content: FortuneContent) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection(content)
                scoreDetailSections(content)
                personalMessageSection(content)
                luckyItemsSection(content)
                shareSection(content)
            }
            .padding()
        }
    }

    // MARK: - 헤더: 날짜 + 요약

    private func headerSection(_ content: FortuneContent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(formattedToday)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(content.energySummary ?? content.summary)
                .font(.title3)
                .fontWeight(.semibold)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("fortune.detail.header")
    }

    private var formattedToday: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 EEEE"
        return formatter.string(from: Date())
    }

    // MARK: - 영역별 상세 섹션

    private func scoreDetailSections(_ content: FortuneContent) -> some View {
        VStack(spacing: 12) {
            scoreDetailCard(
                icon: "heart.fill",
                label: "사랑운",
                score: content.loveScore,
                color: .pink,
                detail: content.loveDetail,
                identifier: "fortune.detail.love"
            )
            scoreDetailCard(
                icon: "wonsign.circle.fill",
                label: "재물운",
                score: content.moneyScore,
                color: .green,
                detail: content.moneyDetail,
                identifier: "fortune.detail.money"
            )
            scoreDetailCard(
                icon: "heart.text.square.fill",
                label: "건강운",
                score: content.healthScore,
                color: .orange,
                detail: content.healthDetail,
                identifier: "fortune.detail.health"
            )
            scoreDetailCard(
                icon: "briefcase.fill",
                label: "직장운",
                score: content.workScore,
                color: .blue,
                detail: content.workDetail,
                identifier: "fortune.detail.work"
            )
        }
    }

    private func scoreDetailCard(
        icon: String,
        label: String,
        score: Int,
        color: Color,
        detail: String?,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)

                Text(label)
                    .font(.headline)

                Spacer()

                scoreDots(score: score, color: color)
            }

            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.85))
                    .lineSpacing(4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }

    private func scoreDots(score: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= score ? color : Color(.systemGray4))
                    .frame(width: 8, height: 8)
            }
        }
    }

    // MARK: - AI 개인화 메시지

    private func personalMessageSection(_ content: FortuneContent) -> some View {
        Group {
            if let message = content.personalMessage {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.purple)
                        Text("오늘의 AI 편지")
                            .font(.headline)
                    }

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.85))
                        .lineSpacing(6)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.purple.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.15), lineWidth: 1)
                )
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("fortune.detail.personalMessage")
            }
        }
    }

    // MARK: - 행운 아이템

    private func luckyItemsSection(_ content: FortuneContent) -> some View {
        HStack(spacing: 16) {
            luckyItem(icon: "sparkle", label: "행운의 숫자", value: "\(content.luckyNumber)")
            luckyItem(icon: "paintpalette.fill", label: "행운의 색", value: content.luckyColor)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("fortune.detail.luckyItems")
    }

    private func luckyItem(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - 공유 버튼

    private func shareSection(_ content: FortuneContent) -> some View {
        ShareLink(item: shareText(content)) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("오늘의 운세 공유하기")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .accessibilityIdentifier("fortune.detail.share")
    }

    static func shareText(_ content: FortuneContent) -> String {
        var text = "[\(formattedDate)] 오늘의 운세\n\n"
        text += "\(content.summary)\n\n"
        text += "사랑 \(dots(content.loveScore)) | "
        text += "재물 \(dots(content.moneyScore)) | "
        text += "건강 \(dots(content.healthScore)) | "
        text += "직장 \(dots(content.workScore))\n\n"
        text += "행운의 숫자: \(content.luckyNumber)\n"
        text += "행운의 색: \(content.luckyColor)\n\n"
        text += "- YAYA 오늘의 운세"
        return text
    }

    private func shareText(_ content: FortuneContent) -> String {
        Self.shareText(content)
    }

    private static var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: Date())
    }

    private static func dots(_ score: Int) -> String {
        String(repeating: "●", count: score) + String(repeating: "○", count: 5 - score)
    }

    // MARK: - 빈 상태

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundColor(.purple.opacity(0.5))

            Text("아직 오늘의 운세가 준비되지 않았어요")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("홈 화면에서 운세를 새로고침 해보세요")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accessibilityIdentifier("fortune.detail.empty")
    }
}
