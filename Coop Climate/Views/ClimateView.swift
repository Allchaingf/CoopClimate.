import SwiftUI

struct ClimateView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = ClimateViewModel()
    @State private var showAddReading = false
    @State private var showAddTask = false
    @State private var toastVisible = false

    var selectedCoop: Coop? {
        appState.coops.first(where: { $0.id == vm.selectedCoopId })
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Coop selector
                    if appState.coops.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "building.2")
                                .font(.system(size: 48))
                                .foregroundColor(Color.appTextInactive)
                            Text("Add a coop first to track climate.")
                                .font(.system(size: 15))
                                .foregroundColor(Color.appTextSecondary)
                        }
                        .padding(.top, 60)
                    } else {
                        // Coop picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(appState.coops) { coop in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            vm.selectedCoopId = coop.id
                                        }
                                    }) {
                                        Text(coop.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(vm.selectedCoopId == coop.id ? .white : Color.appTextSecondary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 9)
                                            .background(vm.selectedCoopId == coop.id ? Color.appPrimary : Color.appCardBackground)
                                            .clipShape(Capsule())
                                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        if let coopId = vm.selectedCoopId {
                            let readings = vm.readings(for: coopId, from: appState)
                            let latest = readings.first
                            let tempValues = vm.temperatureValues(for: coopId, from: appState)
                            let humValues = vm.humidityValues(for: coopId, from: appState)

                            // Gauges
                            HStack(spacing: 16) {
                                ClimateGauge(
                                    value: latest?.temperature ?? 0,
                                    min: 0, max: 45,
                                    unit: "°C",
                                    title: "Temperature",
                                    color: tempColor(latest?.temperature ?? 0)
                                )
                                ClimateGauge(
                                    value: latest?.humidity ?? 0,
                                    min: 0, max: 100,
                                    unit: "%",
                                    title: "Humidity",
                                    color: humColor(latest?.humidity ?? 0)
                                )
                            }
                            .padding(.horizontal, 20)

                            // Risk + Ventilation
                            AppCard {
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Risk Level").font(.system(size: 12)).foregroundColor(Color.appTextInactive)
                                        StatusBadge(
                                            label: latest?.riskLevel.rawValue ?? "—",
                                            color: latest?.riskLevel.color ?? Color.appTextInactive
                                        )
                                    }
                                    Divider().frame(height: 40)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Ventilation").font(.system(size: 12)).foregroundColor(Color.appTextInactive)
                                        Text(latest?.ventilationLevel.rawValue ?? "—")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Color.appTextPrimary)
                                    }
                                    Spacer()
                                    Image(systemName: "wind")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.appCyan)
                                }
                            }
                            .padding(.horizontal, 20)

                            // Temperature chart
                            if tempValues.count > 1 {
                                AppCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Temperature Trend")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color.appTextPrimary)
                                        MiniLineChart(values: tempValues, color: Color.appOrange)
                                        HStack {
                                            Text(String(format: "Min: %.1f°", tempValues.min() ?? 0))
                                            Spacer()
                                            Text(String(format: "Max: %.1f°", tempValues.max() ?? 0))
                                        }
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.appTextInactive)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            // Humidity chart
                            if humValues.count > 1 {
                                AppCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Humidity Trend")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color.appTextPrimary)
                                        MiniLineChart(values: humValues, color: Color.appBlue)
                                        HStack {
                                            Text(String(format: "Min: %.0f%%", humValues.min() ?? 0))
                                            Spacer()
                                            Text(String(format: "Max: %.0f%%", humValues.max() ?? 0))
                                        }
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.appTextInactive)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            // Recent readings
                            if !readings.isEmpty {
                                VStack(spacing: 8) {
                                    SectionHeader(title: "Recent Readings")
                                        .padding(.horizontal, 20)
                                    ForEach(readings.prefix(5)) { r in
                                        ReadingRow(reading: r)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }

                            // Recommendations
                            if let latest = latest {
                                RecommendationCard(reading: latest)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.top, 8)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Climate")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { showAddTask = true }) {
                            Image(systemName: "checklist")
                                .font(.system(size: 18))
                                .foregroundColor(Color.appBlue)
                        }
                        Button(action: { showAddReading = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color.appPrimary)
                        }
                    }
                }
            }
        }
        .onAppear {
            if vm.selectedCoopId == nil { vm.selectedCoopId = appState.coops.first?.id }
        }
        .sheet(isPresented: $showAddReading) { AddClimateReadingSheet().environmentObject(appState) }
        .sheet(isPresented: $showAddTask) { AddTaskSheet().environmentObject(appState) }
        .overlay(alignment: .top) {
            if toastVisible, let msg = vm.toast {
                ToastView(message: msg, icon: "checkmark.circle.fill", color: Color.appPrimary)
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: vm.toast) { toast in
            guard toast != nil else { return }
            withAnimation { toastVisible = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { toastVisible = false }
                vm.toast = nil
            }
        }
    }

    private func tempColor(_ t: Double) -> Color {
        if t > 32 || t < 8 { return Color.appDanger }
        if t > 28 || t < 12 { return Color.appWarning }
        return Color.appPrimary
    }

    private func humColor(_ h: Double) -> Color {
        if h > 85 || h < 30 { return Color.appDanger }
        if h > 75 || h < 40 { return Color.appWarning }
        return Color.appBlue
    }
}

// MARK: - Climate Gauge
private struct ClimateGauge: View {
    let value: Double
    let min: Double
    let max: Double
    let unit: String
    let title: String
    let color: Color

    var body: some View {
        AppCard {
            VStack(spacing: 8) {
                ZStack {
                    GaugeArc(value: value, min: min, max: max, color: color, lineWidth: 12)
                        .frame(width: 90, height: 90)
                    VStack(spacing: 0) {
                        Text(String(format: value >= 10 ? "%.1f" : "%.1f", value))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.appTextPrimary)
                        Text(unit)
                            .font(.system(size: 12))
                            .foregroundColor(Color.appTextInactive)
                    }
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Reading Row
private struct ReadingRow: View {
    let reading: ClimateReading
    private static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .short; f.timeStyle = .short; return f
    }()

    var body: some View {
        AppCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.fmt.string(from: reading.date))
                        .font(.system(size: 12)).foregroundColor(Color.appTextInactive)
                    HStack(spacing: 8) {
                        Label(String(format: "%.1f°", reading.temperature), systemImage: "thermometer")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.appTextPrimary)
                        Label(String(format: "%.0f%%", reading.humidity), systemImage: "humidity")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.appTextPrimary)
                    }
                }
                Spacer()
                StatusBadge(label: reading.riskLevel.rawValue, color: reading.riskLevel.color)
            }
        }
    }
}

// MARK: - Recommendation Card
private struct RecommendationCard: View {
    let reading: ClimateReading

    private var recommendations: [String] {
        var r: [String] = []
        if reading.temperature > 30 { r.append("Increase ventilation to cool down the coop.") }
        if reading.temperature < 10 { r.append("Add supplemental heating to keep birds warm.") }
        if reading.humidity > 75 { r.append("Improve drainage and airflow to reduce moisture.") }
        if reading.humidity < 40 { r.append("Add a water source to increase humidity slightly.") }
        if reading.ventilationLevel == .low { r.append("Consider raising ventilation to at least Medium.") }
        if r.isEmpty { r.append("Conditions are optimal — keep up the great work!") }
        return r
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(Color.appWarning)
                    Text("Recommendations")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                }
                ForEach(recommendations, id: \.self) { rec in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 6, height: 6)
                            .padding(.top, 5)
                        Text(rec)
                            .font(.system(size: 13))
                            .foregroundColor(Color.appTextSecondary)
                    }
                }
            }
        }
    }
}
