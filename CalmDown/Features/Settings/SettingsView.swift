import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext

    // Export
    @State private var isExporting        = false
    @State private var exportURL: URL?    = nil
    @State private var showShareSheet     = false
    @State private var exportError: String? = nil

    // Import
    @State private var showFilePicker     = false
    @State private var importResult: ImportResult? = nil
    @State private var importError: String? = nil
    @State private var showImportResult   = false

    // Backup nudge
    @State private var showBackupWarning  = false

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                wellnessSection
                notificationsSection
                appearanceSection
                healthSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        // Export share sheet
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
        // Import file picker
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        // Import result alert
        .alert("Import Complete", isPresented: $showImportResult) {
            Button("OK") {}
        } message: {
            Text(importResult?.summary ?? "")
        }
        // Error alert (export or import)
        .alert("Error", isPresented: .init(
            get: { exportError != nil || importError != nil },
            set: { if !$0 { exportError = nil; importError = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(exportError ?? importError ?? "")
        }
        .sheet(isPresented: $vm.showBreathing) { BreathingView() }
        .onAppear {
            showBackupWarning = DataExportService.shouldNudgeBackup(context: modelContext)
        }
    }

    // MARK: - Sections

    private var profileSection: some View {
        Section("Profile") {
            HStack {
                Text("Name")
                Spacer()
                TextField("Your name", text: $vm.userName)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var wellnessSection: some View {
        Section("Wellness") {
            Button {
                vm.showBreathing = true
            } label: {
                Label("Breathing Exercise", systemImage: "wind")
            }
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle("Stress Alerts", isOn: $vm.stressAlertsEnabled)
                .tint(Color.calmBlue)
            Toggle("Hydration Reminders", isOn: $vm.hydrationRemindersEnabled)
                .tint(Color.calmBlue)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $vm.selectedTheme) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Text(theme.rawValue).tag(theme)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var healthSection: some View {
        Section("Apple Health") {
            Button {
                Task { try? await HealthKitService.shared.requestAuthorization() }
            } label: {
                Label("Manage Permissions", systemImage: "heart.fill")
            }
        }
    }

    private var dataSection: some View {
        Section {
            // Backup nudge banner
            if showBackupWarning {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Back up your data")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("CalmDown has no cloud backup. If you delete the app you will lose all mood logs, hydration history, and saved HRV readings. Download a backup first.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // Export
            Button {
                exportData()
            } label: {
                HStack {
                    if isExporting {
                        ProgressView().frame(width: 20, height: 20)
                    } else {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                            .foregroundStyle(Color.calmBlue)
                    }
                    Spacer()
                    if let last = DataExportService.lastBackupDate {
                        Text(last, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isExporting)

            // Import / Restore
            Button {
                showFilePicker = true
            } label: {
                Label("Import / Restore Backup", systemImage: "square.and.arrow.down")
                    .foregroundStyle(Color.calmBlue)
            }

        } header: {
            Text("Your Data")
        } footer: {
            Text("CalmDown stores all data on-device only — no cloud, no backend. Export your backup regularly to avoid losing mood logs, hydration history, and HRV readings if you reinstall the app.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0.0")
            LabeledContent("Build",   value: "1")
            Link("Rate on App Store", destination: URL(string: "https://apps.apple.com")!)
            Link("Privacy Policy",    destination: URL(string: "https://calmdown.app/privacy")!)
        }
    }

    // MARK: - Actions

    private func exportData() {
        isExporting = true
        Task {
            do {
                let url = try DataExportService.exportToURL(context: modelContext)
                exportURL         = url
                showShareSheet    = true
                showBackupWarning = false
            } catch {
                exportError = error.localizedDescription
            }
            isExporting = false
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let res = try DataExportService.importFromURL(url, context: modelContext)
                importResult     = res
                showImportResult = true
                showBackupWarning = false
            } catch {
                importError = "Could not read backup file: \(error.localizedDescription)"
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}

// MARK: - ShareSheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environmentObject(StoreKitService.shared)
        .modelContainer(for: [HRVReading.self, MoodEntry.self, HydrationEntry.self], inMemory: true)
}
