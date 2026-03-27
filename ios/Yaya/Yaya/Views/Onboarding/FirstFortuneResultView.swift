import SwiftUI

struct FirstFortuneResultView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let sajuAnalysis: SajuAnalysis?
    let isLoading: Bool
    let onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    loadingView
                } else if let saju = sajuAnalysis {
                    resultView(saju)
                } else {
                    errorView
                }
            }
            .padding()
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 80)

            ProgressView()
                .scaleEffect(1.5)

            Text("사주를 분석하고 있어요...")
                .font(.title3)
                .fontWeight(.medium)

            Text("생년월일과 태어난 시를 기반으로\n당신만의 운세를 만들고 있습니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    // MARK: - Result

    private func resultView(_ saju: SajuAnalysis) -> some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("당신의 사주 분석 결과")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(saju.summary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.top, 16)

            // 오행 비율
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("오행 분석")
                        .font(.headline)
                    Spacer()
                    Text("주요 기운: \(saju.fiveElements.dominant)")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                }

                elementBar(label: "목(木)", value: saju.fiveElements.wood, color: .green)
                elementBar(label: "화(火)", value: saju.fiveElements.fire, color: .red)
                elementBar(label: "토(土)", value: saju.fiveElements.earth, color: .brown)
                elementBar(label: "금(金)", value: saju.fiveElements.metal, color: .gray)
                elementBar(label: "수(水)", value: saju.fiveElements.water, color: .blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

            // 성격 & 특성
            VStack(alignment: .leading, spacing: 12) {
                Text("성격 분석")
                    .font(.headline)

                Text(saju.personality)
                    .font(.subheadline)
                    .lineSpacing(4)

                // 강점
                VStack(alignment: .leading, spacing: 6) {
                    Text("강점")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)

                    FlowLayout(spacing: 8) {
                        ForEach(saju.strengths, id: \.self) { strength in
                            Text(strength)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

            // 재물운 미리보기
            VStack(alignment: .leading, spacing: 8) {
                Text("재물운")
                    .font(.headline)
                Text(saju.wealthFortune)
                    .font(.subheadline)
                    .lineSpacing(4)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

            // CTA
            Button {
                onFinish()
            } label: {
                Text("더 자세히 보기")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
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
        }
    }

    // MARK: - Components

    private func elementBar(label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .frame(width: 44, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                }
            }
            .frame(height: 12)

            Text("\(value)%")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
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
