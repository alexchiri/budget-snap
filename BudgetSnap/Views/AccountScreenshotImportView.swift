import SwiftUI
import PhotosUI
import SwiftData

struct AccountScreenshotImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let account: Account

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
                ProgressView(value: progressValue) {
                    Text(stepDescription)
                        .font(.headline)
                }
                .padding()

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
            .navigationTitle("Import to \(account.name)")
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
                Text("Choose Photos")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .onChange(of: selectedItems) { _, _ in
                Task {
                    await loadSelectedImages()
                    if !selectedImages.isEmpty {
                        processImages()
                    }
                }
            }
        }
    }

    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Processing \(selectedImages.count) screenshot(s)...")
                .font(.title3)
                .fontWeight(.medium)

            Text("Extracting transaction details")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var reviewingView: some View {
        VStack(spacing: 16) {
            if skippedDuplicates > 0 {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Skipped \(skippedDuplicates) duplicate screenshot(s)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }

            if processedTransactions.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text("No New Transactions Found")
                        .font(.headline)

                    Text("The selected screenshots may be duplicates or don't contain recognizable transaction data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

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
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        Text("Found \(processedTransactions.count) transaction(s)")
                            .font(.headline)

                        ForEach(processedTransactions) { transaction in
                            TransactionPreviewCard(transaction: transaction)
                        }
                    }
                    .padding(.horizontal)
                }

                Button(action: saveTransactions) {
                    Text("Save Transactions")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
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
                let ocrResults = try await OCRService.shared.extractText(from: selectedImages)

                var newTransactions: [ParsedTransaction] = []
                skippedDuplicates = 0

                for result in ocrResults where result.success {
                    if DuplicateDetectionService.shared.isScreenshotDuplicate(
                        hash: result.imageHash,
                        accountId: account.id,
                        in: modelContext
                    ) {
                        skippedDuplicates += 1
                        continue
                    }

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
            let batchHash = selectedImages.first.map { OCRService.shared.generateImageHash(from: $0) } ?? ""

            for parsed in processedTransactions {
                if !DuplicateDetectionService.shared.isTransactionDuplicate(
                    amount: parsed.amount,
                    merchant: parsed.merchant,
                    date: parsed.date ?? Date(),
                    accountId: account.id,
                    in: modelContext
                ) {
                    let transaction = Transaction(
                        date: parsed.date ?? Date(),
                        amount: parsed.amount,
                        isIncome: false,
                        merchant: parsed.merchant,
                        transactionDescription: parsed.description,
                        account: account,
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
