//
//  CategoryEditView.swift
//  BudgetSnap
//
//  View for creating/editing categories
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct CategoryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let category: Category?

    @State private var name: String = ""
    @State private var selectedIcon: String = "folder"
    @State private var selectedColor: Color = .blue

    private let availableIcons = [
        "folder", "cart", "fork.knife", "car", "bus", "airplane",
        "house", "bolt", "heart", "pills", "tv", "gamecontroller",
        "bag", "gift", "creditcard", "phone", "wifi", "book",
        "graduationcap", "dumbbell", "pawprint", "leaf"
    ]

    private let availableColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown, .gray
    ]

    var isEditing: Bool {
        category != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(selectedIcon == icon ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(selectedIcon == icon ? Color.blue : Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 15) {
                        ForEach(availableColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 2)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Preview") {
                    HStack {
                        Image(systemName: selectedIcon)
                            .foregroundColor(selectedColor)
                            .frame(width: 40, height: 40)
                            .background(selectedColor.opacity(0.2))
                            .clipShape(Circle())

                        Text(name.isEmpty ? "Category Name" : name)
                            .font(.headline)

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveCategory()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let category = category {
                    name = category.name
                    selectedIcon = category.icon
                    selectedColor = category.color
                }
            }
        }
    }

    private func saveCategory() {
        if let category = category {
            // Edit existing
            category.name = name
            category.icon = selectedIcon
            category.colorHex = selectedColor.toHex()
            category.isDefault = false
        } else {
            // Create new
            let newCategory = Category(
                name: name,
                colorHex: selectedColor.toHex(),
                icon: selectedIcon
            )
            modelContext.insert(newCategory)
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Color Extension

extension Color {
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }

        let r = components[0]
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0

        return String(format: "#%02X%02X%02X",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
}

#Preview {
    CategoryEditView(category: nil)
        .modelContainer(for: Category.self, inMemory: true)
}
