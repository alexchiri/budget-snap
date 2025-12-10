//
//  TransactionEditView.swift
//  BudgetSnap
//
//  View for editing transaction details
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct TransactionEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]

    @Bindable var transaction: Transaction

    @State private var editedMerchant: String = ""
    @State private var editedAmount: String = ""
    @State private var editedDate: Date = Date()
    @State private var editedDescription: String = ""
    @State private var selectedCategory: Category?
    @State private var showingOriginalText = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    TextField("Merchant", text: $editedMerchant)

                    HStack {
                        Text("Amount")
                        TextField("0.00", text: $editedAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker("Type", selection: $transaction.isIncome) {
                        Label("Expense", systemImage: "minus.circle")
                            .tag(false)
                        Label("Income", systemImage: "plus.circle")
                            .tag(true)
                    }
                    .pickerStyle(.segmented)

                    DatePicker("Date", selection: $editedDate, displayedComponents: .date)

                    TextField("Description", text: $editedDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Category") {
                    if categories.isEmpty {
                        Text("No categories available")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            Text("None").tag(nil as Category?)
                            ForEach(categories) { category in
                                Label(category.name, systemImage: category.icon)
                                    .tag(category as Category?)
                            }
                        }
                    }
                }

                Section("Status") {
                    Toggle("Needs Correction", isOn: $transaction.needsCorrection)
                    Toggle("Reviewed", isOn: $transaction.isReviewed)
                }

                if !transaction.originalOCRText.isEmpty {
                    Section("Original OCR Text") {
                        Button(action: { showingOriginalText.toggle() }) {
                            HStack {
                                Text("View Original Text")
                                Spacer()
                                Image(systemName: showingOriginalText ? "chevron.up" : "chevron.down")
                            }
                        }

                        if showingOriginalText {
                            Text(transaction.originalOCRText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
            .onAppear {
                editedMerchant = transaction.merchant
                editedAmount = String(format: "%.2f", transaction.amount)
                editedDate = transaction.date
                editedDescription = transaction.transactionDescription
                selectedCategory = transaction.category
            }
        }
    }

    private func saveChanges() {
        transaction.merchant = editedMerchant
        transaction.amount = Double(editedAmount) ?? transaction.amount
        transaction.date = editedDate
        transaction.transactionDescription = editedDescription
        transaction.category = selectedCategory
        transaction.lastModifiedAt = Date()

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Transaction.self, Category.self,
        configurations: config
    )

    let transaction = Transaction(
        date: Date(),
        amount: 42.50,
        merchant: "Test Store",
        transactionDescription: "Test purchase"
    )
    container.mainContext.insert(transaction)

    return TransactionEditView(transaction: transaction)
        .modelContainer(container)
}
