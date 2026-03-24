import SwiftUI

// MARK: - HP Primary Button
struct HPButton: View {
    let title: String
    var icon: String? = nil
    var style: HPButtonStyle = .primary
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    let action: () -> Void

    enum HPButtonStyle {
        case primary, secondary, destructive, ghost, accent
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.hpBodySemi())
            }
            .foregroundColor(textColor)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.horizontal, 24)
            .padding(.vertical, 15)
            .background(background)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(borderColor, lineWidth: style == .secondary || style == .ghost ? 1.5 : 0)
            )
        }
        .pressScale()
        .disabled(isLoading)
    }

    private var textColor: Color {
        switch style {
        case .primary:     return .white
        case .secondary:   return .hpNavy
        case .destructive: return .white
        case .ghost:       return .hpTextSecondary
        case .accent:      return .white
        }
    }

    @ViewBuilder private var background: some View {
        switch style {
        case .primary:
            LinearGradient.hpPrimary
        case .accent:
            LinearGradient.hpAccentGrad
        case .destructive:
            LinearGradient.hpDangerGrad
        case .secondary:
            Color.hpBackground
        case .ghost:
            Color.clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary: return Color.hpBorder
        case .ghost:     return Color.hpBorder
        default:         return .clear
        }
    }
}

// MARK: - HP Text Field
struct HPTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var errorMessage: String? = nil

    @State private var isSecureVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if #available(iOS 16.0, *) {
                Text(title)
                    .font(.hpCaption())
                    .foregroundColor(.hpTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            } else {
                Text(title)
                    .font(.hpCaption())
                    .foregroundColor(.hpTextSecondary)
                    .textCase(.uppercase)
            }

            HStack(spacing: 10) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(isFocused ? .hpBlue : .hpTextSecondary)
                        .frame(width: 20)
                }

                Group {
                    if isSecure && !isSecureVisible {
                        SecureField(placeholder.isEmpty ? title : placeholder, text: $text)
                    } else {
                        TextField(placeholder.isEmpty ? title : placeholder, text: $text)
                            .keyboardType(keyboardType)
                    }
                }
                .font(.hpBody())
                .foregroundColor(.hpTextPrimary)
                .focused($isFocused)

                if isSecure {
                    Button(action: { isSecureVisible.toggle() }) {
                        Image(systemName: isSecureVisible ? "eye.slash" : "eye")
                            .foregroundColor(.hpTextSecondary)
                            .font(.system(size: 15))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.hpBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isFocused ? Color.hpBlue : (errorMessage != nil ? Color.hpDanger : Color.hpBorder),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
            )
            .animation(.hpFast, value: isFocused)

            if let error = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                    Text(error)
                        .font(.hpCaption2())
                }
                .foregroundColor(.hpDanger)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - HP Stat Card
struct HPStatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var icon: String
    var color: Color = .hpBlue
    var gradient: LinearGradient? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.hpNumeric())
                    .foregroundColor(.hpTextPrimary)

                Text(title)
                    .font(.hpCaption())
                    .foregroundColor(.hpTextSecondary)
                    .lineLimit(1)

                if let sub = subtitle {
                    Text(sub)
                        .font(.hpCaption2())
                        .foregroundColor(color)
                }
            }
        }
        .padding(16)
        .background(Color.hpCard)
        .cornerRadius(16)
        .shadow(color: color.opacity(0.12), radius: 8, x: 0, y: 2)
    }
}

// MARK: - HP Section Header
struct HPSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.hpHeadline())
                .foregroundColor(.hpTextPrimary)
            Spacer()
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.hpCaption())
                        .foregroundColor(.hpBlue)
                }
            }
        }
    }
}

// MARK: - HP Badge
struct HPBadge: View {
    let text: String
    var color: Color = .hpBlue

    var body: some View {
        Text(text)
            .font(.hpCaption2())
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(6)
    }
}

// MARK: - HP Severity Badge
struct HPSeverityBadge: View {
    let severity: IssueSeverity
    var body: some View {
        HPBadge(text: severity.rawValue, color: severity.color)
    }
}

// MARK: - HP Status Badge
struct HPStatusBadge: View {
    let status: IssueStatus
    var body: some View {
        HPBadge(text: status.rawValue, color: status.color)
    }
}

// MARK: - Condition Score Ring
struct ConditionRing: View {
    let score: Double
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.hpBorder, lineWidth: 5)
                .frame(width: size, height: size)
            Circle()
                .trim(from: 0, to: score / 100)
                .stroke(score.conditionColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.hpSlow, value: score)
            Text("\(Int(score))")
                .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                .foregroundColor(.hpTextPrimary)
        }
    }
}

// MARK: - HP Divider
struct HPDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.hpBorder)
            .frame(height: 1)
    }
}

// MARK: - HP Empty State
struct HPEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.hpBlue.opacity(0.08))
                    .frame(width: 90, height: 90)
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundColor(.hpBlue.opacity(0.6))
            }
            VStack(spacing: 8) {
                Text(title)
                    .font(.hpTitle3())
                    .foregroundColor(.hpTextPrimary)
                Text(message)
                    .font(.hpBody())
                    .foregroundColor(.hpTextSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle = actionTitle, let action = action {
                HPButton(title: actionTitle, icon: "plus", style: .primary,
                         isFullWidth: false, action: action)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - HP Toast
struct HPToast: View {
    let message: String
    var isError: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .hpDanger : .hpSuccess)
            Text(message)
                .font(.hpBodySemi())
                .foregroundColor(.hpTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.hpCard)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - HP Navigation Bar
struct HPNavigationBar: View {
    let title: String
    var subtitle: String? = nil
    var onBack: (() -> Void)? = nil
    var trailingIcon: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let onBack = onBack {
                Button(action: onBack) {
                    ZStack {
                        Circle()
                            .fill(Color.hpBackground)
                            .frame(width: 36, height: 36)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.hpTextPrimary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.hpTitle3())
                    .foregroundColor(.hpTextPrimary)
                if let sub = subtitle {
                    Text(sub)
                        .font(.hpCaption())
                        .foregroundColor(.hpTextSecondary)
                }
            }

            Spacer()

            if let trailingIcon = trailingIcon, let trailingAction = trailingAction {
                Button(action: trailingAction) {
                    ZStack {
                        Circle()
                            .fill(Color.hpBackground)
                            .frame(width: 36, height: 36)
                        Image(systemName: trailingIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.hpTextPrimary)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - HP Search Bar
struct HPSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search..."

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.hpTextSecondary)
                .font(.system(size: 15))
            TextField(placeholder, text: $text)
                .font(.hpBody())
                .foregroundColor(.hpTextPrimary)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.hpTextSecondary)
                        .font(.system(size: 15))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.hpBackground)
        .cornerRadius(12)
    }
}

// MARK: - HP Progress Bar
struct HPProgressBar: View {
    let value: Double // 0..1
    var color: Color = .hpBlue
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height/2)
                    .fill(color.opacity(0.15))
                    .frame(height: height)
                RoundedRectangle(cornerRadius: height/2)
                    .fill(color)
                    .frame(width: geo.size.width * min(max(value, 0), 1), height: height)
                    .animation(.hpSpring, value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Image Picker (UIViewControllerRepresentable)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? sourceType : .photoLibrary
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.selectedImage = info[.originalImage] as? UIImage
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - HP Loading View
struct HPLoadingView: View {
    @State private var rotate = false
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.hpBorder, lineWidth: 3)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(LinearGradient.hpPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(rotate ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: rotate)
            }
            .onAppear { rotate = true }

            Text("Loading...")
                .font(.hpCaption())
                .foregroundColor(.hpTextSecondary)
        }
    }
}

// MARK: - HP Picker Row
struct HPPickerRow<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    let title: String
    @Binding var selection: T
    var icon: String? = nil

    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.hpBlue)
                    .frame(width: 24)
            }
            Text(title)
                .font(.hpBody())
                .foregroundColor(.hpTextPrimary)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(Array(T.allCases) as! [T], id: \.self) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .font(.hpBody())
            .foregroundColor(.hpBlue)
        }
    }
}
