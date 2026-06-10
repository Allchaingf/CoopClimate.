import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = HistoryViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                AppTextField(placeholder: "Search history…", text: $vm.searchText, icon: "magnifyingglass")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: vm.filterType == nil) {
                            vm.filterType = nil
                        }
                        ForEach([HistoryEntry.EntityType.coop, .group, .reading, .task, .alert, .expense, .note], id: \.self) { type in
                            FilterChip(label: type.rawValue.capitalized, isSelected: vm.filterType == type) {
                                vm.filterType = (vm.filterType == type) ? nil : type
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)

                let entries = vm.filteredEntries(appState.historyEntries)

                if entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 52))
                            .foregroundColor(Color.appTextInactive)
                        Text("No history found.")
                            .font(.system(size: 15))
                            .foregroundColor(Color.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(entries) { entry in
                                HistoryRow(entry: entry)
                                    .padding(.horizontal, 16)
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - History Row
private struct HistoryRow: View {
    let entry: HistoryEntry
    private static let fmt: DateFormatter = { let f = DateFormatter(); f.dateStyle = .short; f.timeStyle = .short; return f }()

    private var icon: String {
        switch entry.entityType {
        case .coop: return "building.2.fill"
        case .group: return "bird.fill"
        case .reading: return "thermometer"
        case .task: return "checklist"
        case .alert: return "bell.fill"
        case .expense: return "dollarsign.circle.fill"
        case .note: return "note.text"
        case .sensor: return "sensor.tag.radiowaves.forward"
        }
    }

    private var color: Color {
        switch entry.entityType {
        case .coop: return Color.appPrimary
        case .group: return Color.appBlue
        case .reading: return Color.appOrange
        case .task: return Color.appCyan
        case .alert: return Color.appDanger
        case .expense: return Color.appWarning
        case .note: return Color.appTextSecondary
        case .sensor: return Color.appBlueLight
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.action)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.appTextPrimary)
                Text(entry.entityName)
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(Self.fmt.string(from: entry.date))
                .font(.system(size: 11))
                .foregroundColor(Color.appTextInactive)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Filter Chip
private struct FilterChip: View {
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
                .background(isSelected ? Color.appPrimary : Color.appCardBackground)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
}
