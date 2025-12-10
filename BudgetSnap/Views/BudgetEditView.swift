//
//  BudgetEditView.swift
//  BudgetSnap
//
//  View for creating/editing budgets
//

import SwiftUI
import SwiftData

struct BudgetEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]
    @Query private var budgets: [Budget]

    let budget: Budget?
    let monthYear: String

    @State private var selectedCategory: Category?
    @State private var limitAmount: String = ""

    private var isEditing: Bool {
        budget != nil
    }

    private var availableCategories: [Category] {
        if isEditing {
            // When editing, show all categories including current one
            return categories
        } else {
            // When creating, only show categories without budgets for this month
            let usedCategoryIDs = budgets
                .filter { $0.monthYear == monthYear }
                .compactMap { $0.category?.id }

            return categories.filter { !usedCategoryIDs.contains($0.id) }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Month") {
                    Text(formatMonthYear(monthYear))
                        .foregroundColor(.secondary)
                }

                Section("Category") {
                    if availableCategories.isEmpty {
                        Text("All categories have budgets for this month")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Select Category").tag(nil as Category?)
                            ForEach(availableCategories) { category in
                                Label(category.name, systemImage: category.icon)
                                    .tag(category as Category?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Budget Limit") {
                    HStack {
                        Text(Locale.current.currency?.identifier ?? "USD")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $limitAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                if let selectedCategory = selectedCategory {
                    Section("Preview") {
                        HStack {
                            Image(systemName: selectedCategory.icon)
                                .foregroundColor(selectedCategory.color)
                                .frame(width: 40, height: 40)
                                .background(selectedCategory.color.opacity(0.2))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedCategory.name)
                                    .font(.headline)

                                if let amount = Double(limitAmount), amount > 0 {
                                    Text("Limit: \(amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Enter a budget limit")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Budget" : "New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveBudget()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if let budget = budget {
                    selectedCategory = budget.category
                    limitAmount = String(format: "%.2f", budget.limit)
                }
            }
        }
    }

    private var canSave: Bool {
        guard selectedCategory != nil,
              let amount = Double(limitAmount),
              amount > 0 else {
            return false
        }
        return true
    }

    private func formatMonthYear(_ monthYear: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        if let date = formatter.date(from: monthYear) {
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return monthYear
    }

    private func saveBudget() {
        guard let category = selectedCategory,
              let amount = Double(limitAmount) else {
            return
        }

        if let budget = budget {
            // Edit existing
            budget.category = category
            budget.limit = amount
            budget.lastModifiedAt = Date()
        } else {
            // Create new
            let newBudget = Budget(
                category: category,
                monthYear: monthYear,
                limit: amount
            )
            modelContext.insert(newBudget)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    BudgetEditView(budget: nil, monthYear: Budget.currentMonthYear())
        .modelContainer(for: [Budget.self, Category.self], inMemory: true)
}
