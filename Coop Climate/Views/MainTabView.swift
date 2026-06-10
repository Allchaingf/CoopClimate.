import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                    .tabItem { EmptyView() }

                CoopsView()
                    .tag(1)
                    .tabItem { EmptyView() }

                ClimateView()
                    .tag(2)
                    .tabItem { EmptyView() }

                AlertsView()
                    .tag(3)
                    .tabItem { EmptyView() }

                SettingsView()
                    .tag(4)
                    .tabItem { EmptyView() }
            }

            CustomTabBar(selected: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selected: Int
    @EnvironmentObject var appState: AppState

    private let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Dashboard"),
        ("building.2.fill", "Coops"),
        ("thermometer.sun.fill", "Climate"),
        ("bell.badge.fill", "Alerts"),
        ("gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { i in
                tabButton(index: i)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(
            Color.appCardBackground
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -4)
        )
    }

    private func tabButton(index i: Int) -> some View {
        let isSelected = selected == i
        return Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selected = i
            }
        }) {
            VStack(spacing: 4) {
                TabIconView(
                    icon: tabs[i].icon,
                    isSelected: isSelected,
                    showBadge: i == 3 && !appState.activeAlerts.isEmpty
                )
                Text(tabs[i].label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? Color.appPrimary : Color.appTextInactive)
            }
            .frame(maxWidth: .infinity)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
    }
}

private struct TabIconView: View {
    let icon: String
    let isSelected: Bool
    let showBadge: Bool

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)
            }
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.appPrimary : Color.appTextInactive)
                    .frame(width: 44, height: 44)

                if showBadge {
                    Circle()
                        .fill(Color.appDanger)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: 0)
                }
            }
        }
    }
}
