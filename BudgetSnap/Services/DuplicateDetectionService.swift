//
//  DuplicateDetectionService.swift
//  BudgetSnap
//
//  Service for detecting duplicate transactions
//

import Foundation
import SwiftData

class DuplicateDetectionService {
    static let shared = DuplicateDetectionService()

    private init() {}

    // Check if a screenshot has already been processed (with account filter)
    func isScreenshotDuplicate(hash: String, accountId: UUID, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.screenshotHash == hash &&
                transaction.account?.id == accountId
            }
        )

        do {
            let results = try context.fetch(descriptor)
            return !results.isEmpty
        } catch {
            print("Error checking screenshot duplicate: \(error)")
            return false
        }
    }

    // Check if a screenshot has already been processed (without account filter, for backward compatibility)
    func isScreenshotDuplicate(hash: String, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.screenshotHash == hash
            }
        )

        do {
            let results = try context.fetch(descriptor)
            return !results.isEmpty
        } catch {
            print("Error checking screenshot duplicate: \(error)")
            return false
        }
    }

    // Check if a transaction is a duplicate based on key attributes (with account filter)
    func isTransactionDuplicate(
        amount: Double,
        merchant: String,
        date: Date,
        accountId: UUID,
        in context: ModelContext,
        tolerance: TimeInterval = 86400 // 1 day in seconds
    ) -> Bool {
        let startDate = date.addingTimeInterval(-tolerance)
        let endDate = date.addingTimeInterval(tolerance)

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.amount == amount &&
                transaction.merchant == merchant &&
                transaction.date >= startDate &&
                transaction.date <= endDate &&
                transaction.account?.id == accountId
            }
        )

        do {
            let results = try context.fetch(descriptor)
            return !results.isEmpty
        } catch {
            print("Error checking transaction duplicate: \(error)")
            return false
        }
    }

    // Check if a transaction is a duplicate based on key attributes (without account filter, for backward compatibility)
    func isTransactionDuplicate(
        amount: Double,
        merchant: String,
        date: Date,
        in context: ModelContext,
        tolerance: TimeInterval = 86400 // 1 day in seconds
    ) -> Bool {
        let startDate = date.addingTimeInterval(-tolerance)
        let endDate = date.addingTimeInterval(tolerance)

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.amount == amount &&
                transaction.merchant == merchant &&
                transaction.date >= startDate &&
                transaction.date <= endDate
            }
        )

        do {
            let results = try context.fetch(descriptor)
            return !results.isEmpty
        } catch {
            print("Error checking transaction duplicate: \(error)")
            return false
        }
    }

    // Find similar transactions (fuzzy matching)
    func findSimilarTransactions(
        amount: Double,
        merchant: String,
        date: Date,
        accountId: UUID,
        in context: ModelContext,
        amountTolerance: Double = 0.01,
        dateTolerance: TimeInterval = 259200 // 3 days
    ) -> [Transaction] {
        let startDate = date.addingTimeInterval(-dateTolerance)
        let endDate = date.addingTimeInterval(dateTolerance)
        let minAmount = amount - amountTolerance
        let maxAmount = amount + amountTolerance

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { transaction in
                transaction.amount >= minAmount &&
                transaction.amount <= maxAmount &&
                transaction.date >= startDate &&
                transaction.date <= endDate &&
                transaction.account?.id == accountId
            }
        )

        do {
            let results = try context.fetch(descriptor)
            // Filter by merchant similarity
            return results.filter { transaction in
                levenshteinDistance(transaction.merchant, merchant) < 5
            }
        } catch {
            print("Error finding similar transactions: \(error)")
            return []
        }
    }

    // Calculate Levenshtein distance for string similarity
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = s1.lowercased()
        let s2 = s2.lowercased()

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)

        for i in 0...s1.count {
            matrix[i][0] = i
        }

        for j in 0...s2.count {
            matrix[0][j] = j
        }

        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1[s1.index(s1.startIndex, offsetBy: i-1)] == s2[s2.index(s2.startIndex, offsetBy: j-1)] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }

        return matrix[s1.count][s2.count]
    }
}
