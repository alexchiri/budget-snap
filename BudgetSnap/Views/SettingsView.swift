//
//  SettingsView.swift
//  BudgetSnap
//
//  Settings and data management view
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var budgets: [Budget]
    @Query private var categories: [Category]

    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingDeleteAlert = false
    @State private var exportPassword = ""
    @State private var importPassword = ""
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var selectedFileURL: URL?

    var body: some View {
        NavigationStack {
            List {
                Section("Data") {
                    HStack {
                        Label("Transactions", systemImage: "list.bullet")
                        Spacer()
                        Text("\(transactions.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Budgets", systemImage: "chart.pie")
                        Spacer()
                        Text("\(budgets.count)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label("Categories", systemImage: "folder")
                        Spacer()
                        Text("\(categories.count)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Backup & Restore") {
                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                }

                Section("Privacy") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("100% Private", systemImage: "lock.shield")
                            .font(.headline)

                        Text("All data is processed and stored locally on your device. No cloud sync, no tracking, no third-party access.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Danger Zone") {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Budget Snap")
                            .font(.headline)
                        Text("Privacy-First Budget Tracking via Screenshots")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportSheet) {
                ExportDataSheet(
                    password: $exportPassword,
                    isExporting: $isExporting,
                    onExport: exportData
                )
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportDataSheet(
                    password: $importPassword,
                    isImporting: $isImporting,
                    onImport: importData
                )
            }
            .alert("Delete All Data", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all transactions, budgets, and categories. This action cannot be undone.")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .alert("Success", isPresented: .constant(successMessage != nil)) {
                Button("OK") {
                    successMessage = nil
                }
            } message: {
                if let message = successMessage {
                    Text(message)
                }
            }
        }
    }

    // MARK: - Export

    private func exportData() {
        guard !exportPassword.isEmpty else {
            errorMessage = "Please enter a password to encrypt the backup"
            return
        }

        isExporting = true

        Task {
            do {
                let data = try DataExportService.shared.exportData(
                    transactions: transactions,
                    budgets: budgets,
                    categories: categories,
                    password: exportPassword
                )

                // Save to file
                let fileName = "BudgetSnap_Backup_\(Date().formatted(date: .numeric, time: .omitted)).bsbackup"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try data.write(to: tempURL)

                await MainActor.run {
                    // Share file
                    let activityVC = UIActivityViewController(
                        activityItems: [tempURL],
                        applicationActivities: nil
                    )

                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootVC = window.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }

                    isExporting = false
                    showingExportSheet = false
                    exportPassword = ""
                    successMessage = "Data exported successfully!"
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Export failed: \(error.localizedDescription)"
                    isExporting = false
                }
            }
        }
    }

    // MARK: - Import

    private func importData() {
        guard !importPassword.isEmpty else {
            errorMessage = "Please enter the backup password"
            return
        }

        // Present document picker
        let documentPicker = UIDocumentPickerViewController(
            forOpeningContentTypes: [UTType(filenameExtension: "bsbackup")!]
        )

        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = makeDocumentPickerDelegate()

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(documentPicker, animated: true)
        }
    }

    private func processImportFile(url: URL) {
        isImporting = true

        Task {
            do {
                let data = try Data(contentsOf: url)
                let imported = try DataExportService.shared.importData(from: data, password: importPassword)

                // Import categories first (they're referenced by transactions and budgets)
                var categoryMap: [UUID: Category] = [:]
                for catExport in imported.categories {
                    // Check if category already exists
                    if let existing = categories.first(where: { $0.id == catExport.id }) {
                        categoryMap[catExport.id] = existing
                    } else {
                        let category = Category(
                            id: catExport.id,
                            name: catExport.name,
                            colorHex: catExport.colorHex,
                            icon: catExport.icon,
                            isDefault: catExport.isDefault,
                            createdAt: catExport.createdAt
                        )
                        modelContext.insert(category)
                        categoryMap[catExport.id] = category
                    }
                }

                // Import budgets
                for budgetExport in imported.budgets {
                    // Skip if already exists
                    if budgets.contains(where: { $0.id == budgetExport.id }) {
                        continue
                    }

                    let budget = Budget(
                        id: budgetExport.id,
                        category: budgetExport.categoryID.flatMap { categoryMap[$0] },
                        monthYear: budgetExport.monthYear,
                        limit: budgetExport.limit,
                        createdAt: budgetExport.createdAt,
                        lastModifiedAt: budgetExport.lastModifiedAt
                    )
                    modelContext.insert(budget)
                }

                // Import transactions
                for txnExport in imported.transactions {
                    // Skip if already exists
                    if transactions.contains(where: { $0.id == txnExport.id }) {
                        continue
                    }

                    let transaction = Transaction(
                        id: txnExport.id,
                        date: txnExport.date,
                        amount: txnExport.amount,
                        merchant: txnExport.merchant,
                        transactionDescription: txnExport.description,
                        category: txnExport.categoryID.flatMap { categoryMap[$0] },
                        isReviewed: txnExport.isReviewed,
                        needsCorrection: txnExport.needsCorrection,
                        originalOCRText: txnExport.originalOCRText,
                        screenshotHash: txnExport.screenshotHash,
                        createdAt: txnExport.createdAt,
                        lastModifiedAt: txnExport.lastModifiedAt
                    )
                    modelContext.insert(transaction)
                }

                try modelContext.save()

                await MainActor.run {
                    isImporting = false
                    showingImportSheet = false
                    importPassword = ""
                    successMessage = "Data imported successfully!"
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Import failed: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }

    // MARK: - Delete

    private func deleteAllData() {
        for transaction in transactions {
            modelContext.delete(transaction)
        }
        for budget in budgets {
            modelContext.delete(budget)
        }
        for category in categories {
            modelContext.delete(category)
        }

        try? modelContext.save()
        successMessage = "All data deleted"
    }

    // MARK: - Document Picker Delegate

    private func makeDocumentPickerDelegate() -> DocumentPickerDelegate {
        DocumentPickerDelegate { urls in
            if let url = urls.first {
                processImportFile(url: url)
            }
        }
    }
}

// MARK: - Export Sheet

struct ExportDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var password: String
    @Binding var isExporting: Bool
    let onExport: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Encrypt Your Backup")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Enter a strong password to encrypt your data. You'll need this password to restore the backup.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                SecureField("Enter password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button(action: onExport) {
                    if isExporting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Export Data")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(password.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(password.isEmpty || isExporting)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isExporting)
                }
            }
        }
    }
}

// MARK: - Import Sheet

struct ImportDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var password: String
    @Binding var isImporting: Bool
    let onImport: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                Text("Import Backup")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Enter the password used to encrypt your backup file.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                SecureField("Enter password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Button(action: onImport) {
                    if isImporting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Select Backup File")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(password.isEmpty ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(password.isEmpty || isImporting)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Import Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isImporting)
                }
            }
        }
    }
}

// MARK: - Document Picker Delegate

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    private let completion: ([URL]) -> Void

    init(completion: @escaping ([URL]) -> Void) {
        self.completion = completion
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completion(urls)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Transaction.self, Budget.self, Category.self], inMemory: true)
}
