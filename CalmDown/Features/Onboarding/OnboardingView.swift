import SwiftUI
import AuthenticationServices
import HealthKit

// MARK: - Root gate
// Shows onboarding on first launch; MainTabView thereafter.
struct AppRootView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    var body: some View {
        if onboardingComplete {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

// MARK: - Onboarding container
struct OnboardingView: View {
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @AppStorage("userName")           private var userName           = ""

    @State private var page = 0
    @State private var nameInput = ""
    @State private var healthGranted = false
    @State private var signedInWithApple = false
    @State private var isRequestingHealth = false

    private let healthKit = HealthKitService.shared
    private let totalPages = 4

    var body: some View {
        ZStack {
            // Animated background
            LinearGradient(
                colors: [Color.calmLightBlue, Color.calmCream],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page indicator
                HStack(spacing: 6) {
                    ForEach(0..<totalPages, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.calmBlue : Color.calmBlue.opacity(0.2))
                            .frame(width: i == page ? 24 : 8, height: 6)
                            .animation(.spring(response: 0.4), value: page)
                    }
                }
                .padding(.top, Spacing.lg)

                // Page content
                TabView(selection: $page) {
                    welcomePage.tag(0)
                    privacyPage.tag(1)
                    healthPage.tag(2)
                    identityPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)
            }
        }
    }

    // MARK: - Page 0: Welcome
    private var welcomePage: some View {
        OnboardingPageLayout(
            icon: "waveform.path.ecg.rectangle.fill",
            iconColor: Color.calmBlue,
            title: "CalmDown",
            subtitle: "Scientifically monitor your stress through Heart Rate Variability (HRV) — the same biomarker used in clinical research.",
            footnote: "HRV (SDNN) is a validated, non-invasive measure of autonomic nervous system balance and psychological stress. Higher values indicate lower stress and better recovery.\n\nRef: Shaffer & Ginsberg, 2017 — \"An Overview of Heart Rate Variability Metrics and Norms\"",
            buttonTitle: "Get Started",
            buttonAction: { withAnimation { page = 1 } }
        )
    }

    // MARK: - Page 1: Privacy
    private var privacyPage: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.calmBlue)

            VStack(spacing: Spacing.sm) {
                Text("Your Privacy Matters")
                    .font(.calmLargeTitle)
                    .multilineTextAlignment(.center)

                Text("CalmDown processes all health data on-device. We never sell, share, or upload your personal health information.")
                    .font(.calmBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                PrivacyRow(icon: "iphone",        text: "All data stays on your device")
                PrivacyRow(icon: "cloud.slash",   text: "No cloud upload of health metrics")
                PrivacyRow(icon: "eye.slash",     text: "No tracking or analytics")
                PrivacyRow(icon: "trash",         text: "Delete all data anytime in Settings")
            }
            .padding(Spacing.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            .padding(.horizontal, Spacing.md)

            Spacer()

            Button {
                withAnimation { page = 2 }
            } label: {
                Label("Continue", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(OnboardingPrimaryButton())
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Page 2: Connect Apple Health
    private var healthPage: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 64))
                .foregroundStyle(.pink)
                .symbolRenderingMode(.multicolor)

            VStack(spacing: Spacing.sm) {
                Text("Connect Apple Health")
                    .font(.calmLargeTitle)
                    .multilineTextAlignment(.center)

                Text("CalmDown reads HRV, heart rate, sleep, steps, and activity from Apple Health to calculate your real-time stress score.")
                    .font(.calmBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HealthDataRow(icon: "waveform.path.ecg", text: "Heart Rate Variability (HRV)", detail: "Primary stress biomarker")
                HealthDataRow(icon: "heart.fill",        text: "Heart Rate & Resting HR",     detail: "Cardiovascular baseline")
                HealthDataRow(icon: "moon.fill",         text: "Sleep Analysis",              detail: "Recovery quality")
                HealthDataRow(icon: "figure.walk",       text: "Steps & Activity",            detail: "Daily movement")
                HealthDataRow(icon: "ear",               text: "Environmental Audio",         detail: "Noise stress factor")
            }
            .padding(Spacing.lg)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            .padding(.horizontal, Spacing.md)

            Spacer()

            if healthGranted {
                Label("Connected to Apple Health", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.calmCallout)
                    .padding(.bottom, Spacing.sm)
            }

            Button {
                Task { await requestHealthAccess() }
            } label: {
                if isRequestingHealth {
                    ProgressView().tint(.white)
                } else if healthGranted {
                    Label("Continue", systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Connect Apple Health", systemImage: "heart.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(OnboardingPrimaryButton())
            .disabled(isRequestingHealth)
            .padding(.horizontal, Spacing.xl)

            Button("Skip for now") {
                withAnimation { page = 3 }
            }
            .font(.calmCaption)
            .foregroundStyle(.secondary)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Page 3: Identity (Apple Sign In or name)
    private var identityPage: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.calmBlue)

            VStack(spacing: Spacing.sm) {
                Text("What's your name?")
                    .font(.calmLargeTitle)
                    .multilineTextAlignment(.center)

                Text("We'll personalise your daily greeting. No account required.")
                    .font(.calmBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
            }

            // Sign in with Apple
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName]
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, Spacing.xl)

            Text("— or enter your first name —")
                .font(.calmCaption)
                .foregroundStyle(.secondary)

            // Manual name field
            HStack {
                Image(systemName: "person")
                    .foregroundStyle(Color.calmBlue)
                TextField("Your first name", text: $nameInput)
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
            }
            .padding(Spacing.md)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
            .padding(.horizontal, Spacing.xl)

            Spacer()

            Button {
                finishOnboarding()
            } label: {
                Text(nameInput.isEmpty && !signedInWithApple ? "Skip" : "Let's go!")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(OnboardingPrimaryButton())
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Actions

    private func requestHealthAccess() async {
        isRequestingHealth = true
        do {
            try await healthKit.requestAuthorization()
            healthGranted = true
        } catch {
            // User denied or unavailable — still allow proceeding
            print("HealthKit denied:", error)
        }
        isRequestingHealth = false
        withAnimation { page = 3 }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                let given  = credential.fullName?.givenName  ?? ""
                let family = credential.fullName?.familyName ?? ""
                let name   = [given, family].filter { !$0.isEmpty }.joined(separator: " ")
                if !name.isEmpty { nameInput = name }
            }
            signedInWithApple = true
        case .failure(let error):
            print("Apple Sign In failed:", error)
        }
    }

    private func finishOnboarding() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
        userName = trimmed.isEmpty ? "there" : trimmed
        onboardingComplete = true
    }
}

// MARK: - Reusable page layout
struct OnboardingPageLayout: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let footnote: String
    let buttonTitle: String
    let buttonAction: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(iconColor)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.calmLargeTitle)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.calmBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
            }

            if !footnote.isEmpty {
                Text(footnote)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                    .padding(Spacing.md)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                    .padding(.horizontal, Spacing.md)
            }

            Spacer()

            Button(action: buttonAction) {
                Text(buttonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(OnboardingPrimaryButton())
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
    }
}

// MARK: - Small helper views
struct PrivacyRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Color.calmBlue)
                .frame(width: 24)
            Text(text)
                .font(.calmBody)
        }
    }
}

struct HealthDataRow: View {
    let icon: String
    let text: String
    let detail: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Color.calmBlue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(text).font(.calmBody)
                Text(detail).font(.calmCaption2).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - Button style
struct OnboardingPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.calmBody.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .background(
                Color.calmBlue.opacity(configuration.isPressed ? 0.7 : 1.0),
                in: RoundedRectangle(cornerRadius: CornerRadius.full)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(StoreKitService.shared)
}
