//
//  BudgetsView.swift
//  BudgetSnap
//
//  View for managing monthly budgets
//

import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var budgets: [Budget]
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]

    @State private var selectedMonthYear: String = Budget.currentMonthYear()
    @State private var showingAddBudget = false
    @State private var showingMonthPicker = false
    @State private var selectedBudget: Budget?
    @State private var showingEditSheet = false

    var currentMonthBudgets: [Budget] {
        budgets.filter { $0.monthYear == selectedMonthYear }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month selector
                Button {
                    showingMonthPicker = true
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Spacer()
                        Text(formatMonthYear(selectedMonthYear))
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
                .foregroundColor(.primary)

                // Overall spending summary
                overallSummaryCard

                // Budget list
                if currentMonthBudgets.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(currentMonthBudgets) { budget in
                                BudgetCard(
                                    budget: budget,
                                    spent: calculateSpent(for: budget),
                                    onTap: {
                                        selectedBudget = budget
                                        showingEditSheet = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddBudget = true
                        } label: {
                            Label("Add Budget", systemImage: "plus.circle")
                        }

                        Button {
                            copyFromPreviousMonth()
                        } label: {
                            Label("Copy from Last Month", systemImage: "doc.on.doc")
                        }
                        .disabled(!hasPreviousMonthBudgets)
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                BudgetEditView(budget: nil, monthYear: selectedMonthYear)
            }
            .sheet(isPresented: $showingEditSheet) {
                if let budget = selectedBudget {
                    BudgetEditView(budget: budget, monthYear: selectedMonthYear)
                }
            }
            .sheet(isPresented: $showingMonthPicker) {
                MonthPickerView(selectedMonthYear: $selectedMonthYear)
            }
        }
    }

    // MARK: - Overall Summary Card

    private var overallSummaryCard: some View {
        let totalBudget = currentMonthBudgets.reduce(0) { $0 + $1.limit }
        let totalSpent = currentMonthBudgets.reduce(0) { $0 + calculateSpent(for: $1) }
        let remaining = totalBudget - totalSpent
        let progress = totalBudget > 0 ? min(totalSpent / totalBudget, 1.0) : 0

        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(totalBudget, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(remaining, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(remaining < 0 ? .red : .green)
                }
            }

            ProgressView(value: progress)
                .tint(progress > 0.9 ? .red : progress > 0.7 ? .orange : .green)

            HStack {
                Text("Spent: \(totalSpent, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding()
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Budgets")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Set spending limits for each category")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                Button(action: { showingAddBudget = true }) {
                    Label("Add Budget", systemImage: "plus.circle")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                if hasPreviousMonthBudgets {
                    Button(action: copyFromPreviousMonth) {
                        Label("Copy from Last Month", systemImage: "doc.on.doc")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func formatMonthYear(_ monthYear: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        if let date = formatter.date(from: monthYear) {
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return monthYear
    }

    private func calculateSpent(for budget: Budget) -> Double {
        guard let category = budget.category else { return 0 }

        return transactions
            .filter {
                $0.category?.id == category.id &&
                $0.monthYear == selectedMonthYear &&
                !$0.isIncome // Only count expenses, not income
            }
            .reduce(0) { $0 + $1.amount }
    }

    private var hasPreviousMonthBudgets: Bool {
        guard let prevMonth = Budget.previousMonthYear(from: selectedMonthYear) else {
            return false
        }
        return !budgets.filter { $0.monthYear == prevMonth }.isEmpty
    }

    private func copyFromPreviousMonth() {
        guard let prevMonth = Budget.previousMonthYear(from: selectedMonthYear) else {
            return
        }

        let previousBudgets = budgets.filter { $0.monthYear == prevMonth }

        for oldBudget in previousBudgets {
            // Check if budget already exists for this category in current month
            let exists = currentMonthBudgets.contains { $0.category?.id == oldBudget.category?.id }

            if !exists {
                let newBudget = Budget(
                    category: oldBudget.category,
                    monthYear: selectedMonthYear,
                    limit: oldBudget.limit
                )
                modelContext.insert(newBudget)
            }
        }

        try? modelContext.save()
    }
}

// MARK: - Budget Card

struct BudgetCard: View {
    let budget: Budget
    let spent: Double
    let onTap: () -> Void

    private var remaining: Double {
        budget.limit - spent
    }

    private var progress: Double {
        budget.limit > 0 ? min(spent / budget.limit, 1.0) : 0
    }

    private var progressColor: Color {
        if progress > 1.0 {
            return .red
        } else if progress > 0.9 {
            return .orange
        } else if progress > 0.7 {
            return .yellow
        } else {
            return .green
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    if let category = budget.category {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .frame(width: 40, height: 40)
                            .background(category.color.opacity(0.2))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.name)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Limit: \(budget.formattedLimit)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Unknown Category")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(remaining, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                            .font(.headline)
                            .foregroundColor(remaining < 0 ? .red : .primary)

                        Text(remaining < 0 ? "Over budget" : "Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                ProgressView(value: progress)
                    .tint(progressColor)

                HStack {
                    Text("Spent: \(spent, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(progressColor)
                }

                // Alert if over budget or near limit
                if progress >= 1.0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Budget exceeded!")
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                } else if progress >= 0.9 {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("Approaching limit")
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BudgetsView()
        .modelContainer(for: [Budget.self, Category.self, Transaction.self], inMemory: true)
}
