import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    @State private var showLogin  = false
    @State private var showSignUp = false
    @State private var logoScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30

    var body: some View {
        ZStack {
            // Background
            Color.hpBackground.ignoresSafeArea()

            // Top gradient panel
            VStack(spacing: 0) {
                LinearGradient.hpPrimary
                    .frame(height: UIScreen.main.bounds.height * 0.52)
                    .overlay(WelcomeTopContent(logoScale: logoScale))
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
            .hpCornerRadius(36, corners: [.bottomLeft, .bottomRight])

            // Bottom auth panel
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text("Welcome Back")
                            .font(.hpTitle())
                            .foregroundColor(.hpTextPrimary)
                        Text("Monitor and protect your buildings")
                            .font(.hpBody())
                            .foregroundColor(.hpTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    HPButton(title: "Log In", icon: "person.fill", style: .primary) {
                        showLogin = true
                    }

                    HPButton(title: "Create Account", icon: "person.badge.plus", style: .secondary) {
                        showSignUp = true
                    }

                    Text("By continuing, you agree to our Terms of Service")
                        .font(.hpCaption2())
                        .foregroundColor(.hpTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(contentOpacity)
                .offset(y: contentOffset)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                logoScale = 1
                contentOpacity = 1
                contentOffset = 0
            }
        }
        .fullScreenCover(isPresented: $showLogin)  { LogInView() }
        .fullScreenCover(isPresented: $showSignUp) { SignUpView() }
    }
}

struct WelcomeTopContent: View {
    var logoScale: CGFloat

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(Color.white.opacity(0.1)).frame(width: 110, height: 110)
                VStack(spacing: 4) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                    Image(systemName: "house.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.hpAccent)
                }
            }
            .scaleEffect(logoScale)

            Text("HomeInspect Pro")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            HStack(spacing: 24) {
                FeatureChip(icon: "checkmark.shield.fill", text: "Safe")
                FeatureChip(icon: "chart.bar.fill", text: "Track")
                FeatureChip(icon: "wrench.fill", text: "Repair")
            }
            Spacer().frame(height: 20)
        }
    }
}

struct FeatureChip: View {
    let icon: String
    let text: String
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.hpAccent)
            Text(text)
                .font(.hpCaption())
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @EnvironmentObject private var activityVM: ActivityViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var name     = ""
    @State private var email    = ""
    @State private var password = ""
    @State private var nameError: String?    = nil
    @State private var emailError: String?   = nil
    @State private var passwordError: String? = nil
    @State private var isLoading = false
    @State private var appear = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    // Header illustration
                    ZStack {
                        Circle()
                            .fill(LinearGradient.hpPrimary)
                            .frame(width: 90, height: 90)
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    .scaleEffect(appear ? 1 : 0.6)
                    .opacity(appear ? 1 : 0)

                    VStack(spacing: 6) {
                        Text("Create Account")
                            .font(.hpTitle())
                            .foregroundColor(.hpTextPrimary)
                        Text("Start monitoring your buildings today")
                            .font(.hpBody())
                            .foregroundColor(.hpTextSecondary)
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)

                    VStack(spacing: 16) {
                        HPTextField(title: "Full Name", text: $name,
                                    placeholder: "John Smith",
                                    icon: "person.fill",
                                    errorMessage: nameError)
                            .onChange(of: name) { _ in nameError = nil }

                        HPTextField(title: "Email", text: $email,
                                    placeholder: "john@example.com",
                                    icon: "envelope.fill",
                                    keyboardType: .emailAddress,
                                    errorMessage: emailError)
                            .onChange(of: email) { _ in emailError = nil }

                        HPTextField(title: "Password", text: $password,
                                    placeholder: "Min. 6 characters",
                                    icon: "lock.fill",
                                    isSecure: true,
                                    errorMessage: passwordError)
                            .onChange(of: password) { _ in passwordError = nil }
                    }
                    .padding(.horizontal, 24)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)

                    VStack(spacing: 12) {
                        HPButton(title: "Create Account", icon: "checkmark", style: .primary,
                                 isLoading: isLoading) {
                            attemptSignUp()
                        }

                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Text("Already have an account? ")
                                .foregroundColor(.hpTextSecondary)
                            + Text("Log In")
                                .foregroundColor(.hpBlue)
                                .fontWeight(.semibold)
                        }
                        .font(.hpBody())
                    }
                    .padding(.horizontal, 24)
                    .opacity(appear ? 1 : 0)
                }
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading:
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.hpTextSecondary)
                        .font(.system(size: 16, weight: .semibold))
                }
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
        }
    }

    private func attemptSignUp() {
        var valid = true
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            nameError = "Name is required"; valid = false
        }
        if !email.contains("@") || !email.contains(".") {
            emailError = "Enter a valid email"; valid = false
        }
        if password.count < 6 {
            passwordError = "Password must be at least 6 characters"; valid = false
        }
        guard valid else { return }

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            let success = appVM.signUp(name: name, email: email, password: password)
            if success {
                activityVM.addNotification(
                    title: "Welcome to HomeInspect Pro!",
                    body: "Start by adding your first building.",
                    type: .inspectionDue)
                appVM.showSuccessToast("Account created successfully!")
                presentationMode.wrappedValue.dismiss()
            } else {
                emailError = "Sign up failed. Try again."
            }
        }
    }
}

// MARK: - Log In View
struct LogInView: View {
    @EnvironmentObject private var appVM: AppViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var email    = ""
    @State private var password = ""
    @State private var emailError: String?    = nil
    @State private var passwordError: String? = nil
    @State private var isLoading = false
    @State private var appear = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    // Logo
                    ZStack {
                        Circle()
                            .fill(LinearGradient.hpPrimary)
                            .frame(width: 90, height: 90)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    .scaleEffect(appear ? 1 : 0.6)
                    .opacity(appear ? 1 : 0)

                    VStack(spacing: 6) {
                        Text("Welcome Back")
                            .font(.hpTitle())
                            .foregroundColor(.hpTextPrimary)
                        Text("Sign in to your account")
                            .font(.hpBody())
                            .foregroundColor(.hpTextSecondary)
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)

                    VStack(spacing: 16) {
                        HPTextField(title: "Email", text: $email,
                                    placeholder: "your@email.com",
                                    icon: "envelope.fill",
                                    keyboardType: .emailAddress,
                                    errorMessage: emailError)
                            .onChange(of: email) { _ in emailError = nil }

                        HPTextField(title: "Password", text: $password,
                                    placeholder: "Your password",
                                    icon: "lock.fill",
                                    isSecure: true,
                                    errorMessage: passwordError)
                            .onChange(of: password) { _ in passwordError = nil }
                    }
                    .padding(.horizontal, 24)
                    .offset(x: shakeOffset)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)

                    VStack(spacing: 12) {
                        HPButton(title: "Log In", icon: "arrow.right", style: .primary,
                                 isLoading: isLoading) {
                            attemptLogin()
                        }

                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Text("Don't have an account? ")
                                .foregroundColor(.hpTextSecondary)
                            + Text("Sign Up")
                                .foregroundColor(.hpBlue)
                                .fontWeight(.semibold)
                        }
                        .font(.hpBody())
                    }
                    .padding(.horizontal, 24)
                    .opacity(appear ? 1 : 0)

                    // Demo hint
                    Text("Demo: use any email & password (6+ chars)")
                        .font(.hpCaption2())
                        .foregroundColor(.hpTextSecondary)
                        .padding(.bottom, 20)
                        .opacity(appear ? 0.6 : 0)
                }
            }
            .background(Color.hpBackground.ignoresSafeArea())
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading:
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.hpTextSecondary)
                        .font(.system(size: 16, weight: .semibold))
                }
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
        }
    }

    private func attemptLogin() {
        var valid = true
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            emailError = "Enter your email"; valid = false
        }
        if password.isEmpty {
            passwordError = "Enter your password"; valid = false
        }
        guard valid else { return }

        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            let success = appVM.logIn(email: email, password: password)
            if success {
                appVM.showSuccessToast("Welcome back!")
                presentationMode.wrappedValue.dismiss()
            } else {
                passwordError = "Incorrect email or password"
                withAnimation(.spring(response: 0.15, dampingFraction: 0.2)) {
                    shakeOffset = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.2)) {
                        shakeOffset = -10
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring()) { shakeOffset = 0 }
                    }
                }
            }
        }
    }
}
