//
//  CategoriesView.swift
//  BudgetSnap
//
//  View for managing spending categories
//

import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @Query private var transactions: [Transaction]

    @State private var showingAddCategory = false
    @State private var selectedCategory: Category?
    @State private var showingEditSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if categories.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(categories) { category in
                            CategoryRow(category: category, transactionCount: transactionCount(for: category))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCategory = category
                                    showingEditSheet = true
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if !category.isDefault {
                                        Button(role: .destructive) {
                                            deleteCategory(category)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditView(category: nil)
            }
            .sheet(isPresented: $showingEditSheet) {
                if let category = selectedCategory {
                    CategoryEditView(category: category)
                }
            }
            .onAppear {
                if categories.isEmpty {
                    seedDefaultCategories()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Categories")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create categories to organize your transactions")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button(action: seedDefaultCategories) {
                Label("Add Default Categories", systemImage: "folder.badge.plus")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    // MARK: - Helper Methods

    private func transactionCount(for category: Category) -> Int {
        transactions.filter { $0.category?.id == category.id }.count
    }

    private func deleteCategory(_ category: Category) {
        // Remove category from all transactions
        for transaction in transactions where transaction.category?.id == category.id {
            transaction.category = nil
        }

        modelContext.delete(category)
        try? modelContext.save()
    }

    private func seedDefaultCategories() {
        let defaults = Category.createDefaultCategories()
        for category in defaults {
            modelContext.insert(category)
        }
        try? modelContext.save()
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: Category
    let transactionCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
                .frame(width: 40, height: 40)
                .background(category.color.opacity(0.2))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text("\(transactionCount) transaction(s)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if category.isDefault {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("Default")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CategoriesView()
        .modelContainer(for: [Category.self, Transaction.self], inMemory: true)
}
