import SwiftUI

struct BreathingView: View {
    @StateObject private var vm = BreathingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                colors: vm.backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: vm.currentPhase.duration), value: vm.currentPhase)

            VStack(spacing: Spacing.xl) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    VStack {
                        Text("Breathing Exercise")
                            .font(.calmHeadline)
                            .foregroundStyle(.white)
                        Text("Cycle \(vm.sessionCount) of \(vm.totalSessions)")
                            .font(.calmCaption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                    Button { vm.toggleSession() } label: {
                        Image(systemName: vm.isActive ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)

                Spacer()

                // Breathing circle
                BreathingCircleView(phase: $vm.currentPhase)

                // Timer
                Text(vm.timerString)
                    .font(.system(size: 48, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                // Completion progress
                HStack(spacing: Spacing.sm) {
                    ForEach(0..<vm.totalSessions, id: \.self) { i in
                        Circle()
                            .fill(i < vm.sessionCount ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                // Instructions
                Text(vm.instructionText)
                    .font(.calmBody)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.bottom, Spacing.xl)
            }
        }
        .onDisappear { vm.stopSession() }
    }
}

@MainActor
final class BreathingViewModel: ObservableObject {
    @Published var currentPhase:  BreathingPhase = .breatheIn
    @Published var isActive       = false
    @Published var sessionCount   = 0
    @Published var elapsedSeconds = 0

    let totalSessions = 5
    private var timer: Timer?
    private var phaseTimer: Task<Void, Never>?

    var backgroundColors: [Color] {
        switch currentPhase {
        case .breatheIn:  return [.calmDeepGreen, .calmMint.opacity(0.8)]
        case .hold:       return [.calmNavy, .calmLavender.opacity(0.5)]
        case .breatheOut: return [.calmNavy, .calmDeepGreen.opacity(0.7)]
        }
    }

    var timerString: String {
        let min = elapsedSeconds / 60
        let sec = elapsedSeconds % 60
        return String(format: "%02d:%02d", min, sec)
    }

    var instructionText: String {
        switch currentPhase {
        case .breatheIn:  return "Breathe in slowly through your nose..."
        case .hold:       return "Hold your breath gently..."
        case .breatheOut: return "Exhale slowly through your mouth..."
        }
    }

    func toggleSession() {
        if isActive { stopSession() } else { startSession() }
    }

    func startSession() {
        isActive = true
        startPhaseLoop()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedSeconds += 1
            }
        }
    }

    func stopSession() {
        isActive = false
        phaseTimer?.cancel()
        timer?.invalidate()
        timer = nil
    }

    private func startPhaseLoop() {
        phaseTimer?.cancel()
        phaseTimer = Task {
            while !Task.isCancelled && isActive {
                let duration = currentPhase.duration
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else { break }
                if currentPhase == .breatheOut {
                    sessionCount += 1
                    if sessionCount >= totalSessions {
                        stopSession()
                        break
                    }
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPhase = currentPhase.next
                }
            }
        }
    }
}

#Preview {
    BreathingView()
        .environmentObject(StoreKitService.shared)
}
