//
//  TransactionsView.swift
//  BudgetSnap
//
//  Main view for viewing and managing transactions
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct TransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var showingImport = false
    @State private var selectedTransaction: Transaction?
    @State private var showingEditSheet = false
    @State private var filterOption: FilterOption = .all
    @State private var searchText = ""

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case needsReview = "Needs Review"
        case uncategorized = "Uncategorized"
        case categorized = "Categorized"
    }

    var filteredTransactions: [Transaction] {
        var filtered = transactions

        // Apply filter
        switch filterOption {
        case .all:
            break
        case .needsReview:
            filtered = filtered.filter { $0.needsCorrection || !$0.isReviewed }
        case .uncategorized:
            filtered = filtered.filter { $0.category == nil }
        case .categorized:
            filtered = filtered.filter { $0.category != nil }
        }

        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.merchant.localizedCaseInsensitiveContains(searchText) ||
                $0.transactionDescription.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    // Group transactions by month
    var groupedTransactions: [(String, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { $0.monthYear }
        return grouped.sorted { $0.key > $1.key }.map { ($0.key, $0.value) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Filter", selection: $filterOption) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Transactions list
                if filteredTransactions.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(groupedTransactions, id: \.0) { monthYear, transactions in
                            Section(header: Text(formatMonthYear(monthYear))) {
                                ForEach(transactions) { transaction in
                                    TransactionRow(transaction: transaction)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedTransaction = transaction
                                            showingEditSheet = true
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                deleteTransaction(transaction)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                            Button {
                                                toggleReviewed(transaction)
                                            } label: {
                                                Label(
                                                    transaction.isReviewed ? "Unreview" : "Review",
                                                    systemImage: transaction.isReviewed ? "checkmark.circle.fill" : "checkmark.circle"
                                                )
                                            }
                                            .tint(.green)
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search transactions")
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingImport = true
                    } label: {
                        Label("Import", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingImport) {
                ScreenshotImportView()
            }
            .sheet(isPresented: $showingEditSheet) {
                if let transaction = selectedTransaction {
                    TransactionEditView(transaction: transaction)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Transactions")
                .font(.title2)
                .fontWeight(.semibold)

            if filterOption == .all {
                Text("Tap the + button to import screenshots")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                Button(action: { showingImport = true }) {
                    Label("Import Screenshots", systemImage: "photo.stack")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Text("No transactions match this filter")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
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

    private func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
    }

    private func toggleReviewed(_ transaction: Transaction) {
        transaction.isReviewed.toggle()
        transaction.lastModifiedAt = Date()
        try? modelContext.save()
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category indicator
            if let category = transaction.category {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .frame(width: 30, height: 30)
                    .background(category.color.opacity(0.2))
                    .clipShape(Circle())
            } else {
                Image(systemName: "questionmark")
                    .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let category = transaction.category {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Status indicators
                HStack(spacing: 8) {
                    if transaction.needsCorrection {
                        Label("Needs Review", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }

                    if transaction.isReviewed {
                        Label("Reviewed", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TransactionsView()
        .modelContainer(for: [Transaction.self, Budget.self, Category.self], inMemory: true)
}
