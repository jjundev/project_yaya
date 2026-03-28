import SwiftUI

struct FirstFortuneResultView: View {
    let sajuAnalysis: SajuAnalysis?
    let investmentProfile: InvestmentProfile?
    let analysisKey: Int
    let onFinish: () -> Void
    let onRetry: () -> Void

    @State private var showHeader = false
    @State private var showHeroCard = false
    @State private var showElements = false
    @State private var showPersonality = false
    @State private var showStrengths = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    if let saju = sajuAnalysis {
                        resultContent(saju)
                    } else {
                        errorView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }

            // Fixed bottom buttons
            VStack(spacing: 12) {
                Button {
                    onFinish()
                } label: {
                    Text("시작하기")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button {
                    onRetry()
                } label: {
                    Text("다시 입력하기")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 12)
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
            )
            .opacity(showButton ? 1 : 0)
        }
        .task(id: analysisKey) {
            showHeader = false
            showHeroCard = false
            showElements = false
            showPersonality = false
            showStrengths = false
            showButton = false

            let ns: UInt64 = 300_000_000
            withAnimation(.easeOut(duration: 0.4)) { showHeader = true }
            try? await Task.sleep(nanoseconds: ns)
            withAnimation(.easeOut(duration: 0.4)) { showHeroCard = true }
            try? await Task.sleep(nanoseconds: ns)
            withAnimation(.easeOut(duration: 0.4)) { showElements = true }
            try? await Task.sleep(nanoseconds: ns)
            withAnimation(.easeOut(duration: 0.4)) { showPersonality = true }
            try? await Task.sleep(nanoseconds: ns)
            withAnimation(.easeOut(duration: 0.4)) { showStrengths = true }
            try? await Task.sleep(nanoseconds: ns)
            withAnimation(.easeOut(duration: 0.4)) { showButton = true }
        }
    }

    // MARK: - Result Content

    private func resultContent(_ saju: SajuAnalysis) -> some View {
        VStack(spacing: 20) {
            // Header
            Text("분석이 완료되었어요!")
                .font(.system(size: 22, weight: .bold))
                .padding(.top, 8)
                .modifier(FadeSlideIn(show: showHeader))

            // Investment Type Hero Card
            investmentTypeCard
                .modifier(FadeSlideIn(show: showHeroCard))

            // Five Elements Chips
            fiveElementsSection(saju.fiveElements)
                .modifier(FadeSlideIn(show: showElements))

            // Personality Summary
            personalitySummarySection(saju)
                .modifier(FadeSlideIn(show: showPersonality))

            // Strengths
            strengthsSection(saju.strengths)
                .modifier(FadeSlideIn(show: showStrengths))
        }
    }

    // MARK: - Investment Type Hero Card

    private var investmentTypeCard: some View {
        VStack(spacing: 12) {
            let type = investmentProfile?.investmentType

            Text(type?.emoji ?? "📊")
                .font(.system(size: 48))
                .padding(.top, 8)

            Text(type != nil ? "\(type!.displayName) 투자자" : "투자 성향 분석")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.purple)

            Text(investmentProfile?.description ?? type?.shortDescription ?? "사주 기반 투자 성향을 분석했어요")
                .font(.system(size: 13))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.06))
        )
    }

    // MARK: - Five Elements Chips

    private func fiveElementsSection(_ elements: FiveElements) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("나의 오행")
                .font(.system(size: 15, weight: .bold))

            HStack(spacing: 8) {
                elementChip(label: "木", value: elements.wood, color: Color(.systemGreen))
                elementChip(label: "火", value: elements.fire, color: Color(.systemRed))
                elementChip(label: "土", value: elements.earth, color: Color(.systemBrown))
                elementChip(label: "金", value: elements.metal, color: Color(.systemOrange))
                elementChip(label: "水", value: elements.water, color: Color(.systemBlue))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    private func elementChip(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)%")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Personality Summary

    private func personalitySummarySection(_ saju: SajuAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("성격 한 줄 요약")
                .font(.system(size: 15, weight: .bold))

            Text(saju.personality)
                .font(.system(size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Strengths

    private func strengthsSection(_ strengths: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("강점")
                .font(.system(size: 15, weight: .bold))

            ForEach(strengths.prefix(3), id: \.self) { strength in
                HStack(spacing: 8) {
                    Text("✓")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                    Text(strength)
                        .font(.system(size: 13))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 80)

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("분석 중 문제가 발생했어요")
                .font(.title3)
                .fontWeight(.medium)

            Text("걱정 마세요! 메인 화면에서\n다시 확인할 수 있어요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }
}

// MARK: - FadeSlideIn Modifier

private struct FadeSlideIn: ViewModifier {
    let show: Bool

    func body(content: Content) -> some View {
        content
            .opacity(show ? 1 : 0)
            .offset(y: show ? 0 : 16)
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}
