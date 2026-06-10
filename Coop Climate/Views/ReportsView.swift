import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ReportsViewModel()
    @State private var showShareSheet = false
    @State private var exportText = ""
    @State private var toastVisible = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Range picker
                    Picker("Range", selection: $vm.selectedRange) {
                        ForEach(ReportsViewModel.DateRange.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    // Summary cards
                    let readings = vm.filteredReadings(appState.climateReadings)
                    HStack(spacing: 12) {
                        MetricTile(
                            title: "Avg Temp",
                            value: String(format: "%.1f", vm.avgTemperature(appState.climateReadings)),
                            unit: "°C",
                            icon: "thermometer",
                            color: Color.appOrange
                        )
                        MetricTile(
                            title: "Avg Humidity",
                            value: String(format: "%.0f", vm.avgHumidity(appState.climateReadings)),
                            unit: "%",
                            icon: "humidity",
                            color: Color.appBlue
                        )
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 12) {
                        MetricTile(
                            title: "Risk Events",
                            value: "\(vm.riskCount(appState.climateReadings))",
                            unit: "",
                            icon: "exclamationmark.triangle.fill",
                            color: Color.appDanger
                        )
                        MetricTile(
                            title: "Readings",
                            value: "\(readings.count)",
                            unit: "",
                            icon: "chart.xyaxis.line",
                            color: Color.appPrimary
                        )
                    }
                    .padding(.horizontal, 20)

                    // Temperature trend
                    if !readings.isEmpty {
                        let tempVals = readings.sorted { $0.date < $1.date }.map(\.temperature)
                        AppCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Temperature Trend (\(vm.selectedRange.rawValue))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.appTextPrimary)
                                MiniLineChart(values: tempVals, color: Color.appOrange, height: 80)
                                chartLegend(values: tempVals, unit: "°C")
                            }
                        }
                        .padding(.horizontal, 20)

                        let humVals = readings.sorted { $0.date < $1.date }.map(\.humidity)
                        AppCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Humidity Trend (\(vm.selectedRange.rawValue))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.appTextPrimary)
                                MiniLineChart(values: humVals, color: Color.appBlue, height: 80)
                                chartLegend(values: humVals, unit: "%")
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Risk distribution
                    if !readings.isEmpty {
                        let normal = readings.filter { $0.riskLevel == .normal }.count
                        let warning = readings.filter { $0.riskLevel == .warning }.count
                        let danger = readings.filter { $0.riskLevel == .danger }.count

                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Risk Level Distribution")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.appTextPrimary)

                                RiskBar(label: "Normal", count: normal, total: readings.count, color: Color.appPrimary)
                                RiskBar(label: "Warning", count: warning, total: readings.count, color: Color.appWarning)
                                RiskBar(label: "Danger", count: danger, total: readings.count, color: Color.appDanger)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Group comparison
                    if !appState.birdGroups.isEmpty {
                        AppCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Group Overview")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.appTextPrimary)
                                ForEach(appState.birdGroups) { group in
                                    HStack {
                                        Image(systemName: "bird.fill").foregroundColor(Color.appBlue)
                                        Text(group.birdType).font(.system(size: 13)).foregroundColor(Color.appTextPrimary)
                                        Spacer()
                                        Text("\(group.count) birds")
                                            .font(.system(size: 12)).foregroundColor(Color.appTextInactive)
                                        StatusBadge(label: group.status.rawValue, color: group.status.color)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Export buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            exportText = buildReport()
                            showShareSheet = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export PDF")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.appBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appBlue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button(action: {
                            let text = buildReport()
                            UIPasteboard.general.string = text
                            withAnimation { toastVisible = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { toastVisible = false }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Data")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.appPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.appPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [exportText])
        }
        .overlay(alignment: .top) {
            if toastVisible {
                ToastView(message: "Report copied to clipboard", icon: "checkmark.circle.fill", color: Color.appPrimary)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func chartLegend(values: [Double], unit: String) -> some View {
        HStack {
            Text(String(format: "Min: %.1f\(unit)", values.min() ?? 0))
            Spacer()
            Text(String(format: "Avg: %.1f\(unit)", values.reduce(0, +) / Double(max(values.count, 1))))
            Spacer()
            Text(String(format: "Max: %.1f\(unit)", values.max() ?? 0))
        }
        .font(.system(size: 11))
        .foregroundColor(Color.appTextInactive)
    }

    private func buildReport() -> String {
        let r = vm.filteredReadings(appState.climateReadings)
        return """
        Coop Climate Report — \(vm.selectedRange.rawValue)
        Generated: \(Date())

        Readings: \(r.count)
        Avg Temperature: \(String(format: "%.1f", vm.avgTemperature(appState.climateReadings)))°C
        Avg Humidity: \(String(format: "%.0f", vm.avgHumidity(appState.climateReadings)))%
        Risk Events: \(vm.riskCount(appState.climateReadings))

        Coops: \(appState.coops.map(\.name).joined(separator: ", "))
        Groups: \(appState.birdGroups.map { "\($0.birdType) (\($0.count))" }.joined(separator: ", "))
        """
    }
}

// MARK: - Risk Bar
private struct RiskBar: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color

    private var fraction: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color.appTextSecondary)
                .frame(width: 56, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.appDivider).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(color).frame(width: geo.size.width * fraction, height: 8)
                }
            }
            .frame(height: 8)
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
