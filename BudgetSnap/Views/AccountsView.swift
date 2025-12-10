import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct AccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.createdAt, order: .forward) private var accounts: [Account]

    @State private var showingAddAccount = false
    @State private var accountToEdit: Account?

    var body: some View {
        NavigationStack {
            Group {
                if accounts.isEmpty {
                    emptyStateView
                } else {
                    accountsList
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddAccount = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AccountEditView()
            }
            .sheet(item: $accountToEdit) { account in
                AccountEditView(account: account)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Accounts")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first account to start tracking transactions")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                showingAddAccount = true
            } label: {
                Text("Create Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var accountsList: some View {
        List {
            ForEach(accounts) { account in
                NavigationLink {
                    AccountDetailView(account: account)
                } label: {
                    AccountRow(account: account)
                }
            }
            .onDelete(perform: deleteAccounts)
        }
    }

    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            let account = accounts[index]
            modelContext.delete(account)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error deleting account: \(error)")
        }
    }
}

struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(account.color)
                    .frame(width: 50, height: 50)

                Image(systemName: account.icon)
                    .font(.title3)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)

                if let transactions = account.transactions {
                    Text("\(transactions.count) transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("0 transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(account.formattedBalance)
                    .font(.headline)
                    .foregroundColor(account.balance >= 0 ? .primary : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AccountsView()
        .modelContainer(for: [Account.self, Transaction.self])
}
