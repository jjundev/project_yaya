import SwiftUI

struct AnalysisLoadingView: View {
    @State private var step1Complete = false
    @State private var step2Complete = false
    @State private var step3Complete = false
    @State private var isPulsing = false
    @State private var appeared = false

    let sajuAnalysisComplete: Bool
    let analysisFinished: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated icon area
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let iconAngle = time.remainder(dividingBy: 2.0) / 2.0 * 360
                let ringAngle = time.remainder(dividingBy: 4.0) / 4.0 * -360

                ZStack {
                    // Outer dashed ring - rotating
                    Circle()
                        .strokeBorder(
                            Color.purple.opacity(0.2),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(ringAngle))

                    // Pulsing background circle
                    Circle()
                        .fill(Color.purple.opacity(0.08))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isPulsing ? 1.08 : 1.0)

                    // Rotating emoji
                    Text("🔮")
                        .font(.system(size: 48))
                        .rotationEffect(.degrees(iconAngle))
                }
            }

            Spacer().frame(height: 40)

            // Title
            Text("사주를 분석하고 있어요")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(.label))

            Spacer().frame(height: 48)

            // Step indicators
            VStack(alignment: .leading, spacing: 14) {
                stepRow(
                    text: step1Complete ? "사주 팔자 해석 완료" : "사주 팔자 해석 중...",
                    isComplete: step1Complete,
                    isActive: !step1Complete
                )
                stepRow(
                    text: step2Complete ? "오행 에너지 분석 완료" : "오행 에너지 분석 중...",
                    isComplete: step2Complete,
                    isActive: step1Complete && !step2Complete
                )
                stepRow(
                    text: step3Complete ? "투자 성향 분석 완료" : "투자 성향 분석 중...",
                    isComplete: step3Complete,
                    isActive: step2Complete && !step3Complete
                )
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            // Fade in
            withAnimation(.easeIn(duration: 0.4)) {
                appeared = true
            }

            // Start pulse animation
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }

            // Handle case where analysis completed before view appeared
            if sajuAnalysisComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        step1Complete = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        step2Complete = true
                    }
                }
            }
            if analysisFinished {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        step3Complete = true
                    }
                }
            }
        }
        .onChange(of: sajuAnalysisComplete) { _, complete in
            if complete {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    step1Complete = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        step2Complete = true
                    }
                }
            }
        }
        .onChange(of: analysisFinished) { _, finished in
            if finished {
                if !step1Complete {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        step1Complete = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + (step2Complete ? 0.0 : 0.4)) {
                    if !step2Complete {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            step2Complete = true
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            step3Complete = true
                        }
                    }
                }
            }
        }
    }

    private func stepRow(text: String, isComplete: Bool, isActive: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                if isComplete {
                    // Checkmark with bounce
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Dot with optional blinking
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 10, height: 10)
                        .opacity(isActive ? 1 : 0.5)
                        .modifier(BlinkModifier(active: isActive))
                }
            }
            .frame(width: 16, height: 16)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isComplete)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(isComplete ? Color(.label) : Color(.secondaryLabel))
                .animation(.easeInOut(duration: 0.2), value: isComplete)
        }
    }
}

// MARK: - Blink Modifier

private struct BlinkModifier: ViewModifier {
    let active: Bool
    @State private var isVisible = true

    func body(content: Content) -> some View {
        content
            .opacity(active ? (isVisible ? 1.0 : 0.3) : 0.5)
            .onAppear {
                guard active else { return }
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
            .onChange(of: active) { _, newActive in
                if newActive {
                    isVisible = true
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        isVisible = false
                    }
                }
            }
    }
}
