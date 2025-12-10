import SwiftUI
import SwiftData

struct AccountEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account?

    @State private var name: String
    @State private var selectedColor: String
    @State private var selectedIcon: String
    @State private var showError = false
    @State private var errorMessage = ""

    private let availableColors = [
        "#007AFF", "#34C759", "#FF9500", "#FF3B30",
        "#AF52DE", "#FF2D55", "#5AC8FA", "#FFCC00"
    ]

    private let availableIcons = [
        "banknote", "creditcard", "wallet.pass", "dollarsign.circle",
        "building.columns", "chart.line.uptrend.xyaxis", "bag", "cart"
    ]

    init(account: Account? = nil) {
        self.account = account
        _name = State(initialValue: account?.name ?? "")
        _selectedColor = State(initialValue: account?.colorHex ?? "#007AFF")
        _selectedIcon = State(initialValue: account?.icon ?? "banknote")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account Details") {
                    TextField("Account Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedIcon == icon ? Color(hex: selectedColor) ?? .blue : Color(.systemGray5))
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                }
                                .frame(height: 60)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                        ForEach(availableColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color) ?? .blue)
                                        .frame(width: 50, height: 50)
                                    if selectedColor == color {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.title3)
                                            .bold()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(account == nil ? "New Account" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAccount()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveAccount() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter an account name"
            showError = true
            return
        }

        if let account = account {
            // Edit existing account
            account.name = trimmedName
            account.colorHex = selectedColor
            account.icon = selectedIcon
            account.lastModifiedAt = Date()
        } else {
            // Create new account
            let newAccount = Account(
                name: trimmedName,
                colorHex: selectedColor,
                icon: selectedIcon
            )
            modelContext.insert(newAccount)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save account: \(error.localizedDescription)"
            showError = true
        }
    }
}
