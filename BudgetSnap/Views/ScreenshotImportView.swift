//
//  ScreenshotImportView.swift
//  BudgetSnap
//
//  View for importing and processing screenshots
//

import SwiftUI
import PhotosUI
import SwiftData

struct ScreenshotImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isProcessing = false
    @State private var processedTransactions: [ParsedTransaction] = []
    @State private var currentStep: ImportStep = .selecting
    @State private var errorMessage: String?
    @State private var skippedDuplicates = 0

    enum ImportStep {
        case selecting
        case processing
        case reviewing
        case saving
        case complete
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Progress indicator
                ProgressView(value: progressValue) {
                    Text(stepDescription)
                        .font(.headline)
                }
                .padding()

                // Content based on current step
                switch currentStep {
                case .selecting:
                    selectingView
                case .processing:
                    processingView
                case .reviewing:
                    reviewingView
                case .saving:
                    savingView
                case .complete:
                    completeView
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Import Screenshots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
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
        }
    }

    // MARK: - Step Views

    private var selectingView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Select Screenshots")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Choose one or more banking app screenshots to import transactions")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 20,
                matching: .images
            ) {
                Label("Choose Photos", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .onChange(of: selectedItems) { oldValue, newValue in
                Task {
                    await loadSelectedImages()
                }
            }

            if !selectedImages.isEmpty {
                Text("\(selectedImages.count) image(s) selected")
                    .foregroundColor(.secondary)

                Button(action: processImages) {
                    Label("Process Screenshots", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
    }

    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Processing Screenshots...")
                .font(.title3)
                .fontWeight(.medium)

            Text("Extracting transaction data using OCR")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("\(selectedImages.count) screenshot(s)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var reviewingView: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)

                VStack(alignment: .leading) {
                    Text("Found \(processedTransactions.count) Transaction(s)")
                        .font(.headline)

                    if skippedDuplicates > 0 {
                        Text("\(skippedDuplicates) duplicate(s) skipped")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(processedTransactions.enumerated()), id: \.offset) { index, transaction in
                        TransactionPreviewCard(transaction: transaction)
                    }
                }
            }

            Button(action: saveTransactions) {
                Label("Save Transactions", systemImage: "arrow.down.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(processedTransactions.isEmpty)
        }
    }

    private var savingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Saving Transactions...")
                .font(.title3)
                .fontWeight(.medium)
        }
    }

    private var completeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Import Complete!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Successfully imported \(processedTransactions.count) transaction(s)")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button(action: { dismiss() }) {
                Text("Done")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Helper Properties

    private var progressValue: Double {
        switch currentStep {
        case .selecting: return 0.0
        case .processing: return 0.33
        case .reviewing: return 0.66
        case .saving: return 0.85
        case .complete: return 1.0
        }
    }

    private var stepDescription: String {
        switch currentStep {
        case .selecting: return "Step 1: Select Screenshots"
        case .processing: return "Step 2: Processing..."
        case .reviewing: return "Step 3: Review Transactions"
        case .saving: return "Step 4: Saving..."
        case .complete: return "Complete!"
        }
    }

    // MARK: - Helper Methods

    private func loadSelectedImages() async {
        selectedImages = []

        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
    }

    private func processImages() {
        currentStep = .processing
        isProcessing = true

        Task {
            do {
                // Extract text from all images
                let ocrResults = try await OCRService.shared.extractText(from: selectedImages)

                // Check for duplicate screenshots
                var newTransactions: [ParsedTransaction] = []
                skippedDuplicates = 0

                for result in ocrResults where result.success {
                    // Check if screenshot already processed
                    if DuplicateDetectionService.shared.isScreenshotDuplicate(
                        hash: result.imageHash,
                        in: modelContext
                    ) {
                        skippedDuplicates += 1
                        continue
                    }

                    // Parse transactions from OCR text
                    let parsed = TransactionParser.shared.parseTransactions(from: result.text)
                    newTransactions.append(contentsOf: parsed)
                }

                await MainActor.run {
                    processedTransactions = newTransactions
                    currentStep = .reviewing
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to process screenshots: \(error.localizedDescription)"
                    currentStep = .selecting
                    isProcessing = false
                }
            }
        }
    }

    private func saveTransactions() {
        currentStep = .saving

        Task {
            // Get the image hash for the first image (representing this batch)
            let batchHash = selectedImages.first.map { OCRService.shared.generateImageHash(from: $0) } ?? ""

            for parsed in processedTransactions {
                // Check for transaction duplicates
                if !DuplicateDetectionService.shared.isTransactionDuplicate(
                    amount: parsed.amount,
                    merchant: parsed.merchant,
                    date: parsed.date ?? Date(),
                    in: modelContext
                ) {
                    let transaction = Transaction(
                        date: parsed.date ?? Date(),
                        amount: parsed.amount,
                        merchant: parsed.merchant,
                        transactionDescription: parsed.description,
                        isReviewed: false,
                        needsCorrection: parsed.needsReview,
                        originalOCRText: parsed.originalText,
                        screenshotHash: batchHash
                    )

                    modelContext.insert(transaction)
                }
            }

            do {
                try modelContext.save()
                await MainActor.run {
                    currentStep = .complete
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save transactions: \(error.localizedDescription)"
                    currentStep = .reviewing
                }
            }
        }
    }
}

// MARK: - Transaction Preview Card

struct TransactionPreviewCard: View {
    let transaction: ParsedTransaction

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant)
                    .font(.headline)

                if let date = transaction.date {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if transaction.needsReview {
                    Label("Needs Review", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Text(transaction.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.headline)
                .foregroundColor(.primary)

            // Confidence indicator
            Circle()
                .fill(confidenceColor)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private var confidenceColor: Color {
        if transaction.confidence >= 0.8 {
            return .green
        } else if transaction.confidence >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    ScreenshotImportView()
        .modelContainer(for: [Transaction.self, Budget.self, Category.self], inMemory: true)
}
