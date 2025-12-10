import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let account: Account

    @State private var showingImportSheet = false
    @State private var showingEditAccount = false
    @State private var transactionToEdit: Transaction?
    @State private var searchText = ""

    var filteredTransactions: [Transaction] {
        let transactions = account.transactions ?? []
        if searchText.isEmpty {
            return transactions.sorted { $0.date > $1.date }
        }
        return transactions.filter {
            $0.merchant.localizedCaseInsensitiveContains(searchText) ||
            $0.transactionDescription.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                balanceCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            if filteredTransactions.isEmpty {
                Section {
                    emptyStateView
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedTransactionsByMonth.keys.sorted(by: >), id: \.self) { monthYear in
                    Section(header: Text(formatMonthYear(monthYear))) {
                        ForEach(groupedTransactionsByMonth[monthYear] ?? []) { transaction in
                            Button {
                                transactionToEdit = transaction
                            } label: {
                                TransactionRowView(transaction: transaction)
                            }
                        }
                        .onDelete { indexSet in
                            deleteTransactions(at: indexSet, in: monthYear)
                        }
                    }
                }
            }
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search transactions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import Screenshots", systemImage: "photo.stack")
                    }

                    Button {
                        showingEditAccount = true
                    } label: {
                        Label("Edit Account", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            AccountScreenshotImportView(account: account)
        }
        .sheet(isPresented: $showingEditAccount) {
            AccountEditView(account: account)
        }
        .sheet(item: $transactionToEdit) { transaction in
            TransactionEditView(transaction: transaction)
        }
    }

    private var balanceCard: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(account.color)
                        .frame(width: 60, height: 60)

                    Image(systemName: account.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(account.formattedBalance)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(account.balance >= 0 ? .primary : .red)
                }

                Spacer()
            }
            .padding()

            if let transactions = account.transactions, !transactions.isEmpty {
                HStack(spacing: 20) {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("\(transactions.count)")
                            .font(.headline)
                        Text("Transactions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No Transactions")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Import screenshots to add transactions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingImportSheet = true
            } label: {
                Text("Import Screenshots")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var groupedTransactionsByMonth: [String: [Transaction]] {
        Dictionary(grouping: filteredTransactions) { $0.monthYear }
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

    private func deleteTransactions(at offsets: IndexSet, in monthYear: String) {
        guard let transactions = groupedTransactionsByMonth[monthYear] else { return }

        for index in offsets {
            let transaction = transactions[index]
            modelContext.delete(transaction)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error deleting transaction: \(error)")
        }
    }
}

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            if let category = transaction.category {
                ZStack {
                    Circle()
                        .fill(category.color)
                        .frame(width: 40, height: 40)

                    Image(systemName: category.icon)
                        .font(.body)
                        .foregroundColor(.white)
                }
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)

                    Image(systemName: "questionmark")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.body)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if transaction.needsCorrection {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(transaction.isIncome ? .green : .primary)
        }
        .padding(.vertical, 4)
    }
}
