//
//  ContentView.swift
//  BudgetSnap
//
//  Main navigation and tab view
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TransactionsView()
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                }
                .tag(0)

            BudgetsView()
                .tabItem {
                    Label("Budgets", systemImage: "chart.pie")
                }
                .tag(1)

            CategoriesView()
                .tabItem {
                    Label("Categories", systemImage: "folder")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Budget.self, Category.self], inMemory: true)
}
