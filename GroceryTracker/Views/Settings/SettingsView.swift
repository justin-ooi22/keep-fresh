import SwiftUI

/// Settings view for configuring notification alert times, multi-alarm presets, and managing data.
public struct SettingsView: View {
    @EnvironmentObject var store: InventoryStore
    @ObservedObject var notificationManager = NotificationManager.shared
    
    @AppStorage("userColorScheme") private var userColorScheme: String = "system"
    @State private var alertTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var showingResetAlert = false
    @State private var showingTestNotificationSent = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Notification Permission Status
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: notificationManager.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                            .font(.title2)
                            .foregroundColor(notificationManager.isAuthorized ? .green : .orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(notificationManager.isAuthorized ? "Notifications Active" : "Notifications Disabled")
                                .font(.headline)
                            Text(notificationManager.isAuthorized ? "You will receive alerts before items expire." : "Enable notifications in iOS Settings to receive expiry reminders.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if !notificationManager.isAuthorized {
                        Button("Request Notification Access") {
                            Task {
                                _ = await notificationManager.requestAuthorization()
                            }
                        }
                        .font(.subheadline.bold())
                    }
                    
                    Button {
                        notificationManager.sendTestNotification()
                        showingTestNotificationSent = true
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Test Notification (5s)")
                        }
                    }
                } header: {
                    Text("Push Notifications")
                }
                
                // MARK: - Preferred Alert Schedule
                Section {
                    DatePicker(
                        "Daily Reminder Time",
                        selection: $alertTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: alertTime) { _, newTime in
                        let calendar = Calendar.current
                        let hour = calendar.component(.hour, from: newTime)
                        let minute = calendar.component(.minute, from: newTime)
                        notificationManager.preferredAlertHour = hour
                        notificationManager.preferredAlertMinute = minute
                        store.alertHour = hour
                        store.alertMinute = minute
                        notificationManager.rescheduleAll(items: store.items, zones: store.zones)
                    }
                } header: {
                    Text("Reminder Time of Day")
                } footer: {
                    Text("The hour when you will receive expiry alerts on your iPhone.")
                }
                
                // MARK: - Default Alarms for New Items
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("These alarms will be checked by default whenever you scan or add a new grocery item. You can customize them per item.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(NotificationReminderOption.allCases) { option in
                            Toggle(isOn: Binding(
                                get: { store.defaultReminderOptions.contains(option) },
                                set: { isOn in
                                    if isOn {
                                        if !store.defaultReminderOptions.contains(option) {
                                            store.defaultReminderOptions.append(option)
                                        }
                                    } else {
                                        store.defaultReminderOptions.removeAll { $0 == option }
                                    }
                                }
                            )) {
                                HStack {
                                    Text(option.title)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(option.shortBadge)
                                        .font(.caption.bold())
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Default Alarms (Multi-Alarm)")
                }
                
                // MARK: - Appearance
                Section("Appearance (Light & Dark Mode)") {
                    Picker("Theme", selection: $userColorScheme) {
                        Text("System Auto").tag("system")
                        Text("Light Mode").tag("light")
                        Text("Dark Mode").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - House Zones Link
                Section("House Storage") {
                    NavigationLink(destination: ZonesListView()) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.purple)
                            Text("Manage House Storage Rooms")
                            Spacer()
                            Text("\(store.zones.count) rooms")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - Data Management
                Section("Sample Data & Reset") {
                    Button("Reload Sample Groceries") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .navigationTitle("Settings")
            .alert("Reload Sample Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reload", role: .destructive) {
                    store.loadSampleData()
                }
            } message: {
                Text("This will replace your current items with sample groceries across your house rooms.")
            }
            .alert("Test Notification Scheduled", isPresented: $showingTestNotificationSent) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Lock your iPhone or minimize the app! The test alert will fire in 5 seconds.")
            }
            .onAppear {
                notificationManager.checkAuthorization()
            }
        }
    }
}
