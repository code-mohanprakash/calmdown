import SwiftUI

struct SettingsView: View {
    @StateObject private var vm     = SettingsViewModel()
    @StateObject private var storeKit = StoreKitService.shared

    var body: some View {
        NavigationStack {
            Form {
                // Profile section
                Section("Profile") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Your name", text: $vm.userName)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }

                // Premium section
                Section("Premium") {
                    if storeKit.isPremium {
                        Label("CalmDown Premium Active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Color.calmMint)
                    } else {
                        Button {
                            vm.showPremium = true
                        } label: {
                            HStack {
                                Label("Unlock Premium", systemImage: "star.fill")
                                    .foregroundStyle(Color.calmMint)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                // Breathing
                Section("Wellness") {
                    Button {
                        if storeKit.isPremium {
                            vm.showBreathing = true
                        } else {
                            vm.showPremium = true
                        }
                    } label: {
                        HStack {
                            Label("Breathing Exercise", systemImage: "wind")
                            if !storeKit.isPremium {
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Notifications section
                Section("Notifications") {
                    Toggle("Stress Alerts", isOn: $vm.stressAlertsEnabled)
                        .tint(Color.calmMint)
                    Toggle("Hydration Reminders", isOn: $vm.hydrationRemindersEnabled)
                        .tint(Color.calmMint)
                }

                // Theme section
                Section("Appearance") {
                    Picker("Theme", selection: $vm.selectedTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Health section
                Section("Apple Health") {
                    Button {
                        Task { try? await HealthKitService.shared.requestAuthorization() }
                    } label: {
                        Label("Manage Permissions", systemImage: "heart.fill")
                    }
                }

                // About section
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Build",   value: "1")
                    Link("Rate on App Store", destination: URL(string: "https://apps.apple.com")!)
                    Link("Privacy Policy",    destination: URL(string: "https://calmdown.app/privacy")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $vm.showPremium) {
            PremiumView()
        }
        .sheet(isPresented: $vm.showBreathing) {
            BreathingView()
        }
    }
}

#Preview {
    SettingsView()
}
