import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ExpensesViewModel()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Category filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChipE(label: "All", isSelected: vm.filterCategory == nil) { vm.filterCategory = nil }
                            ForEach(Expense.ExpenseCategory.allCases, id: \.self) { cat in
                                FilterChipE(label: cat.rawValue, isSelected: vm.filterCategory == cat) {
                                    vm.filterCategory = vm.filterCategory == cat ? nil : cat
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 4)

                    // Total
                    AppCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Expenses")
                                    .font(.system(size: 12)).foregroundColor(Color.appTextInactive)
                                Text(String(format: "$%.2f", vm.totalAmount(appState.expenses)))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color.appTextPrimary)
                            }
                            Spacer()
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(Color.appWarning)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Category breakdown
                    if !appState.expenses.isEmpty {
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("By Category").font(.system(size: 14, weight: .semibold)).foregroundColor(Color.appTextPrimary)
                                ForEach(Expense.ExpenseCategory.allCases, id: \.self) { cat in
                                    let total = appState.expenses.filter { $0.category == cat }.reduce(0) { $0 + $1.amount }
                                    if total > 0 {
                                        HStack {
                                            Image(systemName: cat.icon).foregroundColor(cat.color).frame(width: 20)
                                            Text(cat.rawValue).font(.system(size: 13)).foregroundColor(Color.appTextPrimary)
                                            Spacer()
                                            Text(String(format: "$%.2f", total))
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(cat.color)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Expense list
                    let filtered = vm.filteredExpenses(appState.expenses).sorted { $0.date > $1.date }
                    if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundColor(Color.appTextInactive)
                            Text("No expenses yet.")
                                .font(.system(size: 15))
                                .foregroundColor(Color.appTextSecondary)
                        }
                        .padding(.top, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(filtered) { expense in
                                ExpenseRow(expense: expense)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { vm.showAddExpense = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.appPrimary)
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showAddExpense) { AddExpenseSheet(vm: vm) }
    }
}

// MARK: - Expense Row
private struct ExpenseRow: View {
    @EnvironmentObject var appState: AppState
    let expense: Expense
    private static let fmt: DateFormatter = { let f = DateFormatter(); f.dateStyle = .medium; return f }()

    var body: some View {
        AppCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(expense.category.color.opacity(0.12)).frame(width: 40, height: 40)
                    Image(systemName: expense.category.icon).font(.system(size: 18)).foregroundColor(expense.category.color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(expense.title).font(.system(size: 14, weight: .semibold)).foregroundColor(Color.appTextPrimary)
                    Text(Self.fmt.string(from: expense.date)).font(.system(size: 12)).foregroundColor(Color.appTextInactive)
                }
                Spacer()
                Text(String(format: "$%.2f", expense.amount))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(expense.category.color)
                Button(action: { appState.deleteExpense(expense) }) {
                    Image(systemName: "xmark.circle").font(.system(size: 16)).foregroundColor(Color.appTextInactive)
                }
            }
        }
    }
}

// MARK: - Add Expense Sheet
private struct AddExpenseSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var vm: ExpensesViewModel
    @State private var showError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    AppTextField(placeholder: "Expense Title *", text: $vm.newTitle, icon: "tag")
                    AppTextField(placeholder: "Amount *", text: $vm.newAmount, icon: "dollarsign.circle")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        Picker("Category", selection: $vm.newCategory) {
                            ForEach(Expense.ExpenseCategory.allCases, id: \.self) { c in
                                Label(c.rawValue, systemImage: c.icon).tag(c)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .background(Color.appSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date").font(.system(size: 13, weight: .medium)).foregroundColor(Color.appTextSecondary)
                        DatePicker("", selection: $vm.newDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(10)
                            .background(Color.appSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    AppTextField(placeholder: "Notes", text: $vm.newNotes, icon: "note.text")

                    if showError {
                        Text("Please fill required fields.").font(.system(size: 13)).foregroundColor(Color.appDanger)
                    }

                    PrimaryButton("Add Expense", icon: "checkmark") {
                        if vm.saveExpense(appState: appState) {
                            presentationMode.wrappedValue.dismiss()
                        } else { showError = true }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }
}

// MARK: - Filter Chip
private struct FilterChipE: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : Color.appTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.appWarning : Color.appCardBackground)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}
