import SwiftUI
import AuthenticationServices
import HealthKit
import SwiftData
import UniformTypeIdentifiers
import UserNotifications

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

    @Environment(\.modelContext) private var modelContext

    @State private var page = 0
    @State private var nameInput = ""
    @State private var healthGranted = false
    @State private var signedInWithApple = false
    @State private var isRequestingHealth = false
    @State private var notifPermissionGranted = false

    // Restore from backup
    @State private var showRestorePicker  = false
    @State private var restoreResult: ImportResult? = nil
    @State private var showRestoreResult  = false
    @State private var restoreError: String? = nil

    private let healthKit = HealthKitService.shared
    private let totalPages = 5

    var body: some View {
        ZStack {
            // Warm sky blue background — matches the app
            Color.calmCream
                .ignoresSafeArea()

            // Soft ambient glow
            Circle()
                .fill(Color.calmBlue.opacity(0.06))
                .frame(width: 360, height: 360)
                .blur(radius: 60)
                .offset(x: -60, y: -120)
                .allowsHitTesting(false)

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
                    notificationsPage.tag(3)
                    identityPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)
            }
        }
    }

    // MARK: - Page 0: Welcome
    private var welcomePage: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            // Mr. Fizz hero with glow
            ZStack {
                Circle()
                    .fill(Color.stressGreat.opacity(0.15))
                    .frame(width: 190, height: 190)
                    .blur(radius: 24)
                MrFizzView(stressLevel: .great, size: 140)
            }

            // App name + tagline
            VStack(spacing: Spacing.sm) {
                Text("CalmDown")
                    .font(.calmLargeTitle)

                Text("Scientifically monitor your stress through Heart Rate Variability — the same biomarker used in clinical research.")
                    .font(.calmBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }

            // Science reference card
            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundStyle(Color.calmBlue)
                        .font(.system(size: 16))
                    Text("HRV (SDNN) — a validated, non-invasive measure of autonomic nervous system balance.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: Spacing.sm) {
                    Image(systemName: "books.vertical")
                        .foregroundStyle(Color.calmBlue)
                        .font(.system(size: 16))
                    Text("Based on: Shaffer & Ginsberg (2017) · ESC Task Force (1996)")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.md)
            .liquidGlass(cornerRadius: CornerRadius.md)
            .padding(.horizontal, Spacing.md)

            Spacer()

            Button {
                withAnimation { page = 1 }
            } label: {
                Label("Get Started", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(OnboardingPrimaryButton())
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Page 1: Privacy
    private var privacyPage: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.calmBlue.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.calmBlue)
                    .symbolRenderingMode(.hierarchical)
            }

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
            .liquidGlass(cornerRadius: CornerRadius.lg)
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

            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.pink)
                    .symbolRenderingMode(.multicolor)
            }

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
            .liquidGlass(cornerRadius: CornerRadius.lg)
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

    // MARK: - Page 3: Notifications
    private var notificationsPage: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.calmBlue.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.calmBlue)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: Spacing.sm) {
                Text("Stay On Track")
                    .font(.calmLargeTitle)
                    .multilineTextAlignment(.center)

                Text("Let CalmDown gently remind you to breathe, hydrate, and check in with your stress levels.")
                    .font(.calmBody)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
            }

            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle().fill(Color.calmCoral.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: "waveform.path.ecg").foregroundStyle(Color.calmCoral).font(.system(size: 20))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stress Alerts").font(.calmBody)
                        Text("Notified when HRV indicates high stress").font(.calmCaption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.calmBlue)
                }

                Divider()

                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle().fill(Color.blue.opacity(0.12)).frame(width: 44, height: 44)
                        Image(systemName: "drop.fill").foregroundStyle(.blue).font(.system(size: 20))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hydration Reminders").font(.calmBody)
                        Text("Gentle nudges to hit your water goal").font(.calmCaption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.calmBlue)
                }
            }
            .padding(Spacing.lg)
            .liquidGlass(cornerRadius: CornerRadius.lg)
            .padding(.horizontal, Spacing.md)

            Spacer()

            Button {
                Task { await requestNotificationPermission() }
            } label: {
                Label(notifPermissionGranted ? "Notifications On — Continue" : "Enable Notifications", systemImage: notifPermissionGranted ? "checkmark.circle.fill" : "bell.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(OnboardingPrimaryButton())
            .padding(.horizontal, Spacing.xl)

            Button("Skip") {
                withAnimation { page = 4 }
            }
            .font(.calmCaption)
            .foregroundStyle(.secondary)
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Page 4: Identity (Apple Sign In or name)
    private var identityPage: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.calmBlue.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.calmBlue)
                    .symbolRenderingMode(.hierarchical)
            }

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
            .liquidGlass(cornerRadius: CornerRadius.md)
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

            // Restore from backup option
            Button {
                showRestorePicker = true
            } label: {
                Label("Restore from backup file", systemImage: "square.and.arrow.down")
                    .font(.calmCaption)
                    .foregroundStyle(Color.calmBlue.opacity(0.8))
            }
            .padding(.bottom, Spacing.xl)
        }
        .fileImporter(
            isPresented: $showRestorePicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            handleRestore(result: result)
        }
        .alert("Data Restored", isPresented: $showRestoreResult) {
            Button("Continue") { finishOnboarding() }
        } message: {
            Text(restoreResult?.summary ?? "")
        }
        .alert("Restore Failed", isPresented: .init(
            get: { restoreError != nil },
            set: { if !$0 { restoreError = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(restoreError ?? "")
        }
    }

    // MARK: - Actions

    private func requestHealthAccess() async {
        isRequestingHealth = true
        do {
            try await healthKit.requestAuthorization()
            healthGranted = true
        } catch {
            print("HealthKit denied:", error)
        }
        isRequestingHealth = false
        withAnimation { page = 3 }
    }

    private func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            notifPermissionGranted = granted
            if granted {
                UserDefaults.standard.set(true, forKey: "stressAlerts")
                UserDefaults.standard.set(true, forKey: "hydrationReminders")
            }
        } catch {
            print("Notification permission error:", error)
        }
        withAnimation { page = 4 }
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

    private func handleRestore(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let res = try DataExportService.importFromURL(url, context: modelContext)
                restoreResult    = res
                showRestoreResult = true
                if let name = UserDefaults.standard.string(forKey: "userName"), !name.isEmpty {
                    nameInput = name
                }
            } catch {
                restoreError = "Could not read backup: \(error.localizedDescription)"
            }
        case .failure(let error):
            restoreError = error.localizedDescription
        }
    }

    private func finishOnboarding() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
        userName = trimmed.isEmpty ? "there" : trimmed
        onboardingComplete = true
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
        .modelContainer(for: [HRVReading.self, MoodEntry.self, HydrationEntry.self], inMemory: true)
}
