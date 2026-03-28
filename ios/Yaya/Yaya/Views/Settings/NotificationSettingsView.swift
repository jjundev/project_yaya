import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("notificationEnabled") private var isEnabled = false
    @AppStorage("notificationTimeInterval") private var timeInterval: Double = Self.defaultTimeInterval
    @StateObject private var notificationManager = NotificationManager()
    @Environment(\.openURL) private var openURL

    private var notificationTime: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: timeInterval) },
            set: { timeInterval = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        List {
            Section {
                Toggle("일일 운세 알림", isOn: $isEnabled)
                    .accessibilityIdentifier("settings.notification.toggle")
                    .onChange(of: isEnabled) { _, newValue in
                        if newValue {
                            handleToggleOn()
                        }
                    }
            } footer: {
                Text("매일 설정한 시간에 오늘의 운세 알림을 받습니다")
            }

            if isEnabled {
                Section("수신 시간") {
                    DatePicker(
                        "알림 시간",
                        selection: notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .accessibilityIdentifier("settings.notification.timePicker")
                }
            }

            if notificationManager.authorizationStatus == .denied {
                Section {
                    Button {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            openURL(settingsURL)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("알림이 차단되어 있습니다. 설정에서 알림을 허용해주세요.")
                                .font(.footnote)
                        }
                    }
                    .accessibilityIdentifier("settings.notification.deniedGuide")
                }
            }
        }
        .navigationTitle("알림 설정")
        .task {
            await notificationManager.checkAuthorizationStatus()
        }
    }

    private func handleToggleOn() {
        Task {
            if notificationManager.authorizationStatus == .notDetermined {
                let granted = await notificationManager.requestAuthorization()
                if !granted {
                    isEnabled = false
                }
            } else if notificationManager.authorizationStatus == .denied {
                // 이미 거부된 상태 — 토글은 켜지지만 안내 표시됨
            }
        }
    }

    static let defaultTimeInterval: Double = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? Date()
        return date.timeIntervalSince1970
    }()
}
