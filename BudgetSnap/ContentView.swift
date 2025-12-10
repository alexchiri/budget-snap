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
    @Query private var accounts: [Account]
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BudgetsView()
                .tabItem {
                    Label("Budget", systemImage: "chart.pie")
                }
                .tag(0)

            AccountsView()
                .tabItem {
                    Label("Accounts", systemImage: "wallet.pass")
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
        .modelContainer(for: [Account.self, Transaction.self, Budget.self, Category.self], inMemory: true)
}
