import SwiftUI

struct StepProgressView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            progressBar
            stepIndicators
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.beautySubText.opacity(0.2))
                    .frame(height: 6)
                Capsule()
                    .fill(Color.beautyRose)
                    .frame(
                        width: totalSteps > 0
                            ? geo.size.width * CGFloat(currentStep) / CGFloat(totalSteps)
                            : 0,
                        height: 6
                    )
                    .animation(.easeInOut, value: currentStep)
            }
        }
        .frame(height: 6)
    }

    private var stepIndicators: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(1...max(1, totalSteps), id: \.self) { step in
                VStack(spacing: 4) {
                    stepIcon(for: step)
                    Text("Step\(step)")
                        .font(.system(size: 9))
                        .foregroundColor(.beautySubText)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func stepIcon(for step: Int) -> some View {
        if step < currentStep {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.beautyRose)
                .font(.system(size: 20))
        } else if step == currentStep {
            Image(systemName: "circle.fill")
                .foregroundColor(Color.beautyRose)
                .font(.system(size: 20))
        } else {
            Image(systemName: "clock.fill")
                .foregroundColor(Color.beautySubText.opacity(0.35))
                .font(.system(size: 20))
        }
    }
}
