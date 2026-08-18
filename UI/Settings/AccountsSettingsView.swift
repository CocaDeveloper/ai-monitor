import SwiftUI

struct AccountsSettingsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var pendingRemoval: ProviderAccount?
    @State private var editingAccount: ProviderAccount?
    @State private var newName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Accounts").font(.title2.bold())
                Spacer()
                Button { environment.addAccountPresented = true } label: { Label("Add", systemImage: "plus") }
            }
            if environment.accounts.isEmpty {
                ContentUnavailableView("No Accounts", systemImage: "person.crop.circle.badge.plus", description: Text("Add Codex / OpenAI to begin."))
            } else {
                List {
                    ForEach(environment.accounts) { account in
                        HStack(spacing: 12) {
                            Image(systemName: account.providerID == .codex ? "terminal" : "film")
                                .foregroundStyle(account.providerID == .codex ? .green : .blue)
                            VStack(alignment: .leading) {
                                Text(account.displayName).font(.headline)
                                Text(account.emailHint ?? account.status.userFacingText).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Refresh") { Task { await environment.refresh(accountID: account.id, force: true) } }
                            Menu {
                                Button("Rename") { editingAccount = account; newName = account.displayName }
                                Button("Reconnect") { Task { await environment.connect(accountID: account.id) } }
                                Button("Disconnect") { Task { await environment.disconnect(accountID: account.id) } }
                                Divider()
                                Button("Remove", role: .destructive) { pendingRemoval = account }
                            } label: { Image(systemName: "ellipsis.circle") }
                            .menuStyle(.borderlessButton)
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove(perform: environment.moveAccounts)
                }
            }
        }
        .sheet(isPresented: $environment.addAccountPresented) { AddAccountView() }
        .alert("Remove account?", isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } })) {
            Button("Cancel", role: .cancel) { pendingRemoval = nil }
            Button("Remove", role: .destructive) {
                if let id = pendingRemoval?.id { environment.remove(accountID: id) }
                pendingRemoval = nil
            }
        } message: {
            Text("AI Monitor will remove this account and its saved snapshot. The isolated Codex sign-in directory remains on disk until you remove it from Application Support.")
        }
        .alert("Rename account", isPresented: Binding(get: { editingAccount != nil }, set: { if !$0 { editingAccount = nil } })) {
            TextField("Account name", text: $newName)
            Button("Cancel", role: .cancel) { editingAccount = nil }
            Button("Save") {
                if let id = editingAccount?.id { environment.rename(accountID: id, name: newName) }
                editingAccount = nil
            }
        }
    }
}

