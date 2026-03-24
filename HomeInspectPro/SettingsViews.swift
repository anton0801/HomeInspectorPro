import SwiftUI
import UserNotifications

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject private var appVM:       AppViewModel
    @EnvironmentObject private var issuesVM:    IssuesViewModel
    @EnvironmentObject private var materialsVM: MaterialsViewModel
    @EnvironmentObject private var activityVM:  ActivityViewModel

    @State private var showProfile        = false
    @State private var showAbout          = false
    @State private var showReports        = false
    @State private var showPhotos         = false
    @State private var showMaterials      = false
    @State private var showMeasurements   = false
    @State private var showIssues         = false
    @State private var showNotifications  = false
    @State private var showClearConfirm   = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Text("Settings").font(.hpTitle()).foregroundColor(.hpTextPrimary)
                            Spacer()
                            Button(action: { showNotifications = true }) {
                                ZStack(alignment: .topTrailing) {
                                    Circle().fill(Color.hpCard).frame(width: 42, height: 42)
                                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                                    Image(systemName: "bell.fill").font(.system(size: 17)).foregroundColor(.hpTextPrimary)
                                    if activityVM.unreadCount > 0 {
                                        Circle().fill(Color.hpDanger).frame(width: 10, height: 10).offset(x: 2, y: -2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20).padding(.top, 16)

                        // Profile quick card
                        Button(action: { showProfile = true }) {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(LinearGradient.hpPrimary)
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Text(String(appVM.currentUser?.name.prefix(1) ?? "?").uppercased())
                                            .font(.hpTitle3()).foregroundColor(.white)
                                    )
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(appVM.currentUser?.name ?? "Inspector")
                                        .font(.hpHeadline()).foregroundColor(.hpTextPrimary)
                                    Text(appVM.currentUser?.email ?? "")
                                        .font(.hpCaption()).foregroundColor(.hpTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.hpTextSecondary)
                            }
                            .hpCard()
                        }
                        .pressScale()
                        .padding(.horizontal, 20)

                        // Quick Access Section
                        SettingsSection(title: "Sections") {
                            QuickNavRow(icon: "exclamationmark.triangle.fill", iconColor: .hpDanger,
                                        title: "Issues", badge: "\(issuesVM.openIssues.count) open",
                                        badgeColor: issuesVM.openIssues.isEmpty ? .hpSuccess : .hpDanger) {
                                showIssues = true
                            }
                            HPDivider()
                            QuickNavRow(icon: "chart.bar.doc.horizontal.fill", iconColor: .hpBlue,
                                        title: "Reports & Analytics") { showReports = true }
                            HPDivider()
                            QuickNavRow(icon: "camera.fill", iconColor: Color(hex: "#AF52DE"),
                                        title: "Photos", badge: "\(issuesVM.photos.count)") { showPhotos = true }
                            HPDivider()
                            QuickNavRow(icon: "cube.box.fill", iconColor: .hpAccent,
                                        title: "Materials", badge: "\(materialsVM.materials.count)") { showMaterials = true }
                            HPDivider()
                            QuickNavRow(icon: "ruler.fill", iconColor: Color(hex: "#5AC8FA"),
                                        title: "Measurements") { showMeasurements = true }
                        }

                        // Appearance section
                        SettingsSection(title: "Appearance") {
                            ThemeSettingsRow()
                            HPDivider()
                            UnitSystemRow()
                        }

                        // Notifications section
                        SettingsSection(title: "Notifications") {
                            NotificationsToggleRow()
                            HPDivider()
                            InspectionRemindersRow()
                            HPDivider()
                            RepairRemindersRow()
                            HPDivider()
                            ReminderDaysRow()
                        }

                        // Data section
                        SettingsSection(title: "Data") {
                            HStack {
                                Image(systemName: "icloud.and.arrow.up").foregroundColor(.hpBlue).frame(width: 24)
                                Text("Export Data").font(.hpBody()).foregroundColor(.hpTextPrimary)
                                Spacer()
                                Text("CSV").font(.hpCaption()).foregroundColor(.hpTextSecondary)
                                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.hpTextSecondary)
                            }
                            .onTapGesture { appVM.showSuccessToast("Data exported to CSV") }

                            HPDivider()
                            HStack {
                                Image(systemName: "trash.fill").foregroundColor(.hpDanger).frame(width: 24)
                                Text("Clear All Data").font(.hpBody()).foregroundColor(.hpDanger)
                                Spacer()
                            }
                            .onTapGesture { showClearConfirm = true }
                        }

                        // About section
                        SettingsSection(title: "About") {
                            HStack {
                                Image(systemName: "info.circle.fill").foregroundColor(.hpBlue).frame(width: 24)
                                Text("About HomeInspect Pro").font(.hpBody()).foregroundColor(.hpTextPrimary)
                                Spacer()
                                Text("v1.0").font(.hpCaption()).foregroundColor(.hpTextSecondary)
                                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.hpTextSecondary)
                            }
                            .onTapGesture { showAbout = true }

                            HPDivider()
                            HStack {
                                Image(systemName: "star.fill").foregroundColor(.hpAccent).frame(width: 24)
                                Text("Rate the App").font(.hpBody()).foregroundColor(.hpTextPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right.square").font(.system(size: 13)).foregroundColor(.hpTextSecondary)
                            }
                            .onTapGesture { appVM.showSuccessToast("Thank you for rating!") }
                        }

                        HPButton(title: "Log Out", icon: "rectangle.portrait.and.arrow.right",
                                 style: .destructive) { appVM.logOut() }
                            .padding(.horizontal, 20)

                        Text("HomeInspect Pro v1.0.0")
                            .font(.hpCaption2()).foregroundColor(.hpTextSecondary)
                            .padding(.bottom, 100)
                    }
                    .padding(.top, 4)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showProfile)       { ProfileView() }
            .sheet(isPresented: $showAbout)         { AboutView() }
            .sheet(isPresented: $showReports)       { ReportsView() }
            .sheet(isPresented: $showPhotos)        { PhotosView() }
            .sheet(isPresented: $showMaterials)     { MaterialsView() }
            .sheet(isPresented: $showMeasurements)  { MeasurementsView() }
            .sheet(isPresented: $showIssues)        { IssuesView() }
            .sheet(isPresented: $showNotifications) { NotificationsView() }
            .actionSheet(isPresented: $showClearConfirm) {
                ActionSheet(
                    title: Text("Clear All Data"),
                    message: Text("This will permanently delete all your buildings, inspections, issues, and repairs. This cannot be undone."),
                    buttons: [
                        .destructive(Text("Clear Everything")) { clearAllData() },
                        .cancel()
                    ]
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func clearAllData() {
        UserDefaults.standard.dictionaryRepresentation().keys
            .filter { $0.hasPrefix("hp_") && $0 != "hp_isLoggedIn" && $0 != "hp_themeMode" && $0 != "hp_unitSystem" }
            .forEach { UserDefaults.standard.removeObject(forKey: $0) }
        appVM.showSuccessToast("All data cleared")
    }
}

// MARK: - Quick Navigation Row
struct QuickNavRow: View {
    let icon: String
    var iconColor: Color = .hpBlue
    let title: String
    var badge: String? = nil
    var badgeColor: Color = .hpBlue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.12)).frame(width: 34, height: 34)
                    Image(systemName: icon).font(.system(size: 15)).foregroundColor(iconColor)
                }
                Text(title).font(.hpBody()).foregroundColor(.hpTextPrimary)
                Spacer()
                if let badge = badge {
                    Text(badge).font(.hpCaption()).foregroundColor(badgeColor)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(badgeColor.opacity(0.1)).cornerRadius(8)
                }
                Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(.hpTextSecondary)
            }
        }
    }
}

// MARK: - Settings Section Container
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title).font(.hpCaption()).foregroundColor(.hpTextSecondary).tracking(0.5)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 20)
            VStack(spacing: 0) { content }
                .hpCard()
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Theme Row
struct ThemeSettingsRow: View {
    @EnvironmentObject private var appVM: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "circle.lefthalf.filled").foregroundColor(.hpBlue).frame(width: 24)
                Text("Theme").font(.hpBody()).foregroundColor(.hpTextPrimary)
                Spacer()
                Text(themeName).font(.hpCaption()).foregroundColor(.hpTextSecondary)
            }
            HStack(spacing: 10) {
                ThemeChip(label: "System", icon: "iphone",    isSelected: appVM.themeMode == "system") { appVM.themeMode = "system" }
                ThemeChip(label: "Light",  icon: "sun.max",   isSelected: appVM.themeMode == "light")  { appVM.themeMode = "light"  }
                ThemeChip(label: "Dark",   icon: "moon.fill", isSelected: appVM.themeMode == "dark")   { appVM.themeMode = "dark"   }
            }
        }
    }

    private var themeName: String {
        switch appVM.themeMode {
        case "light": return "Light"
        case "dark":  return "Dark"
        default:      return "System"
        }
    }
}

struct ThemeChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : .hpTextSecondary)
                Text(label).font(.hpCaption2())
                    .foregroundColor(isSelected ? .white : .hpTextSecondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(isSelected ? LinearGradient.hpPrimary :
                LinearGradient(colors: [Color.hpBackground, Color.hpBackground], startPoint: .top, endPoint: .bottom))
            .cornerRadius(10)
        }
        .animation(.hpFast, value: isSelected)
    }
}

// MARK: - Unit System Row
struct UnitSystemRow: View {
    @EnvironmentObject private var appVM: AppViewModel
    var body: some View {
        HStack {
            Image(systemName: "ruler").foregroundColor(.hpBlue).frame(width: 24)
            Text("Measurement Units").font(.hpBody()).foregroundColor(.hpTextPrimary)
            Spacer()
            Picker("", selection: $appVM.unitSystem) {
                Text("Metric").tag("metric")
                Text("Imperial").tag("imperial")
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 160)
        }
    }
}

// MARK: - Notifications Toggles
struct NotificationsToggleRow: View {
    @EnvironmentObject private var appVM: AppViewModel
    var body: some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(appVM.notificationsEnabled ? .hpBlue : .hpTextSecondary).frame(width: 24)
            Text("Enable Notifications").font(.hpBody()).foregroundColor(.hpTextPrimary)
            Spacer()
            Toggle("", isOn: Binding(
                get: { appVM.notificationsEnabled },
                set: { newVal in
                    if newVal { appVM.requestNotificationPermission() }
                    else {
                        appVM.notificationsEnabled = false
                        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    }
                }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .hpBlue))
        }
    }
}

struct InspectionRemindersRow: View {
    @EnvironmentObject private var appVM: AppViewModel
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass.circle.fill")
                .foregroundColor(appVM.inspectionReminders ? Color(hex: "#AF52DE") : .hpTextSecondary).frame(width: 24)
            Text("Inspection Reminders").font(.hpBody()).foregroundColor(.hpTextPrimary)
            Spacer()
            Toggle("", isOn: $appVM.inspectionReminders)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#AF52DE")))
                .disabled(!appVM.notificationsEnabled)
        }
        .opacity(appVM.notificationsEnabled ? 1 : 0.5)
    }
}

struct RepairRemindersRow: View {
    @EnvironmentObject private var appVM: AppViewModel
    var body: some View {
        HStack {
            Image(systemName: "wrench.fill")
                .foregroundColor(appVM.repairReminders ? .hpAccent : .hpTextSecondary).frame(width: 24)
            Text("Repair Reminders").font(.hpBody()).foregroundColor(.hpTextPrimary)
            Spacer()
            Toggle("", isOn: $appVM.repairReminders)
                .toggleStyle(SwitchToggleStyle(tint: .hpAccent))
                .disabled(!appVM.notificationsEnabled)
        }
        .opacity(appVM.notificationsEnabled ? 1 : 0.5)
    }
}

struct ReminderDaysRow: View {
    @EnvironmentObject private var appVM: AppViewModel
    var body: some View {
        HStack {
            Image(systemName: "calendar.badge.clock").foregroundColor(.hpBlue).frame(width: 24)
            Text("Remind Before").font(.hpBody()).foregroundColor(.hpTextPrimary)
            Spacer()
            Stepper("\(appVM.reminderDaysBefore) day\(appVM.reminderDaysBefore == 1 ? "" : "s")",
                    value: $appVM.reminderDaysBefore, in: 1...14)
                .font(.hpBody()).foregroundColor(.hpBlue)
        }
        .opacity(appVM.notificationsEnabled ? 1 : 0.5)
        .disabled(!appVM.notificationsEnabled)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name  = ""
    @State private var email = ""
    @State private var isEditing = false
    @State private var nameError: String?  = nil
    @State private var emailError: String? = nil
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        ZStack {
                            Circle().fill(LinearGradient.hpPrimary).frame(width: 100, height: 100)
                                .shadow(color: Color.hpNavy.opacity(0.3), radius: 16, x: 0, y: 6)
                            Text(String(name.prefix(1)).uppercased())
                                .font(.system(size: 44, weight: .bold, design: .rounded)).foregroundColor(.white)
                        }
                        .padding(.top, 20)

                        if isEditing {
                            VStack(spacing: 16) {
                                HPTextField(title: "Full Name", text: $name,
                                            placeholder: "Your full name", icon: "person.fill",
                                            errorMessage: nameError)
                                    .onChange(of: name) { _ in nameError = nil }
                                HPTextField(title: "Email", text: $email,
                                            placeholder: "your@email.com", icon: "envelope.fill",
                                            keyboardType: .emailAddress, errorMessage: emailError)
                                    .onChange(of: email) { _ in emailError = nil }
                            }
                            .padding(.horizontal, 24)
                            HStack(spacing: 12) {
                                HPButton(title: "Cancel", style: .secondary) {
                                    isEditing = false
                                    name  = appVM.currentUser?.name  ?? ""
                                    email = appVM.currentUser?.email ?? ""
                                }
                                HPButton(title: "Save", icon: "checkmark", style: .primary,
                                         isLoading: isSaving) { saveProfile() }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            VStack(spacing: 8) {
                                Text(name).font(.hpTitle2()).foregroundColor(.hpTextPrimary)
                                Text(email).font(.hpBody()).foregroundColor(.hpTextSecondary)
                            }
                            VStack(spacing: 12) {
                                ProfileInfoRow(icon: "person.fill",   label: "Name",  value: name)
                                HPDivider()
                                ProfileInfoRow(icon: "envelope.fill", label: "Email", value: email)
                            }
                            .hpCard()
                            .padding(.horizontal, 24)
                            HPButton(title: "Edit Profile", icon: "pencil", style: .secondary) { isEditing = true }
                                .padding(.horizontal, 24)
                        }
                        Color.clear.frame(height: 40)
                    }
                }
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue)
            )
        }
        .onAppear {
            name  = appVM.currentUser?.name  ?? ""
            email = appVM.currentUser?.email ?? ""
        }
    }

    private func saveProfile() {
        var valid = true
        if name.trimmingCharacters(in: .whitespaces).isEmpty { nameError = "Name required"; valid = false }
        if !email.contains("@") { emailError = "Valid email required"; valid = false }
        guard valid else { return }
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if var user = appVM.currentUser {
                user.name  = name
                user.email = email
                appVM.currentUser = user
                UserDefaults.standard.set(try? JSONEncoder().encode(user), forKey: "hp_user")
            }
            appVM.showSuccessToast("Profile updated!")
            isSaving = false
            isEditing = false
        }
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(.hpBlue).frame(width: 22)
            Text(label).font(.hpBody()).foregroundColor(.hpTextSecondary)
            Spacer()
            Text(value).font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @EnvironmentObject private var activityVM: ActivityViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()
                if activityVM.notifications.isEmpty {
                    HPEmptyState(icon: "bell.slash", title: "No Notifications",
                                 message: "You're all caught up! Notifications will appear here.")
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(activityVM.notifications) { notification in
                                NotificationCard(notification: notification)
                                    .onTapGesture { activityVM.markRead(notification) }
                                    .padding(.horizontal, 20)
                                    .contextMenu {
                                        Button { activityVM.markRead(notification) } label: {
                                            Label("Mark as Read", systemImage: "checkmark.circle")
                                        }
                                        Button(role: .destructive) {
                                            activityVM.deleteNotification(notification)
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                            Color.clear.frame(height: 40)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationBarTitle("Notifications", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue),
                trailing: activityVM.unreadCount > 0 ?
                    AnyView(Button("Mark All Read") { activityVM.markAllRead() }.foregroundColor(.hpBlue)) :
                    AnyView(EmptyView())
            )
        }
    }
}

struct NotificationCard: View {
    let notification: NotificationItem
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.hpBlue.opacity(notification.isRead ? 0.06 : 0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: notification.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(notification.isRead ? .hpTextSecondary : .hpBlue)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(notification.title).font(.hpBodySemi())
                        .foregroundColor(notification.isRead ? .hpTextSecondary : .hpTextPrimary)
                    if !notification.isRead {
                        Circle().fill(Color.hpBlue).frame(width: 6, height: 6)
                    }
                }
                Text(notification.body).font(.hpCaption()).foregroundColor(.hpTextSecondary).lineLimit(2)
                Text(notification.createdAt.relativeFormatted).font(.hpCaption2()).foregroundColor(.hpTextSecondary)
            }
        }
        .padding(14).background(Color.hpCard).cornerRadius(14)
        .shadow(color: Color.black.opacity(notification.isRead ? 0.03 : 0.07), radius: 6, x: 0, y: 2)
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationView {
            ZStack {
                Color.hpBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        ZStack {
                            Circle().fill(LinearGradient.hpPrimary).frame(width: 100, height: 100)
                            VStack(spacing: 4) {
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.system(size: 36, weight: .bold)).foregroundColor(.white)
                                Image(systemName: "house.fill")
                                    .font(.system(size: 20)).foregroundColor(.hpAccent)
                            }
                        }
                        .padding(.top, 30)
                        VStack(spacing: 6) {
                            Text("HomeInspect Pro").font(.hpTitle()).foregroundColor(.hpTextPrimary)
                            Text("Version 1.0.0").font(.hpBody()).foregroundColor(.hpTextSecondary)
                        }
                        Text("HomeInspect Pro helps property owners, builders, engineers, and contractors monitor building conditions, track defects, plan repairs, and maintain complete inspection histories.")
                            .font(.hpBody()).foregroundColor(.hpTextSecondary)
                            .multilineTextAlignment(.center).lineSpacing(4)
                            .padding(.horizontal, 24)
                        VStack(spacing: 12) {
                            AboutFeatureRow(icon: "building.2.fill",              title: "Multi-Building Support", desc: "Manage unlimited properties")
                            AboutFeatureRow(icon: "exclamationmark.triangle.fill", title: "Issue Tracking",         desc: "Log and resolve defects")
                            AboutFeatureRow(icon: "camera.fill",                  title: "Photo Documentation",    desc: "Capture visual evidence")
                            AboutFeatureRow(icon: "wrench.fill",                  title: "Repair Planning",         desc: "Schedule and track repairs")
                            AboutFeatureRow(icon: "chart.bar.fill",               title: "Analytics & Reports",     desc: "Insights and condition scores")
                        }
                        .hpCard()
                        .padding(.horizontal, 20)
                        Text("© 2024 HomeInspect Pro. All rights reserved.")
                            .font(.hpCaption2()).foregroundColor(.hpTextSecondary)
                            .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitle("About", displayMode: .inline)
            .navigationBarItems(leading:
                Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(.hpBlue)
            )
        }
    }
}

struct AboutFeatureRow: View {
    let icon: String
    let title: String
    let desc: String
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.hpBlue.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(.hpBlue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.hpBodySemi()).foregroundColor(.hpTextPrimary)
                Text(desc).font(.hpCaption()).foregroundColor(.hpTextSecondary)
            }
            Spacer()
        }
    }
}
