import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var safariURL: URL?
    @State private var confirmReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                NavigationLink {
                    TripStatsView()
                } label: {
                    DeskSurface {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundStyle(Palette.primary)
                                .frame(width: 22)
                            Text("Pulse")
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(Palette.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                DeskSurface {
                    Toggle(isOn: Binding(
                        get: { store.remindersEnabled },
                        set: { store.setRemindersEnabled($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gate reminders")
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(Palette.primary)
                            Text("Local alerts 3 days and 1 day before each departure.")
                                .font(.system(.caption, design: .default))
                                .foregroundStyle(Palette.accent)
                        }
                    }
                    .tint(Palette.primary)
                }
                .padding(.horizontal, 16)
                DeskSurface {
                    VStack(alignment: .leading, spacing: 12) {
                        settingsButton("Rate Us", symbol: "star.fill") {
                            AppLinks.rateApp()
                        }
                        settingsButton("Privacy", symbol: "doc.text") {
                            safariURL = AppLinks.privacy.url
                        }
                        settingsButton("Terms", symbol: "doc.plaintext") {
                            safariURL = AppLinks.terms.url
                        }
                    }
                }
                .padding(.horizontal, 16)
                DeskSurface {
                    Button {
                        confirmReset = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset All Data")
                                .font(.system(.headline, design: .rounded))
                            Spacer()
                        }
                        .foregroundStyle(Palette.primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .padding(.top, 16)
        }
        .clearScrollBackground()
        .deskBackdrop()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: Binding(
            get: { safariURL != nil },
            set: { presented in
                if presented == false {
                    safariURL = nil
                }
            }
        )) {
            if let safariURL {
                SafariSheet(url: safariURL)
            }
        }
        .confirmationDialog("Erase every trip, kit seal, and friction tag?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset All Data", role: .destructive) {
                store.resetAllData()
            }
            Button("Cancel", role: .cancel) { }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            confirmReset = false
        }
    }

    private func settingsButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: symbol)
                    .foregroundStyle(Palette.primary)
                    .frame(width: 22)
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Palette.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.accent)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
