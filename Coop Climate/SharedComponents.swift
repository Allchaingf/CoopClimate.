import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [Color.appPrimary, Color.appPrimaryActive], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.appPrimary.opacity(0.35), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(Color.appTextPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(hex: "E2E8F0"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
    }
}

// MARK: - Card
struct AppCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.appTextPrimary)
            Spacer()
            if let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.appPrimary)
                }
            }
        }
    }
}

// MARK: - Metric Tile
struct MetricTile: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    var trend: String? = nil

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                    Spacer()
                    if let trend = trend {
                        Text(trend)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.appTextInactive)
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                    Text(unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.appTextSecondary)
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.appTextInactive)
            }
        }
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Mini Chart
struct MiniLineChart: View {
    let values: [Double]
    let color: Color
    var height: CGFloat = 60

    private var normalized: [Double] {
        guard let min = values.min(), let max = values.max(), max > min else {
            return values.map { _ in 0.5 }
        }
        return values.map { ($0 - min) / (max - min) }
    }

    var body: some View {
        GeometryReader { geo in
            if normalized.count > 1 {
                Path { path in
                    let step = geo.size.width / CGFloat(normalized.count - 1)
                    path.move(to: CGPoint(x: 0, y: geo.size.height * (1 - normalized[0])))
                    for i in 1..<normalized.count {
                        path.addLine(to: CGPoint(x: step * CGFloat(i), y: geo.size.height * (1 - normalized[i])))
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                Path { path in
                    let step = geo.size.width / CGFloat(normalized.count - 1)
                    path.move(to: CGPoint(x: 0, y: geo.size.height * (1 - normalized[0])))
                    for i in 1..<normalized.count {
                        path.addLine(to: CGPoint(x: step * CGFloat(i), y: geo.size.height * (1 - normalized[i])))
                    }
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                    path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [color.opacity(0.25), color.opacity(0.0)], startPoint: .top, endPoint: .bottom))
            }
        }
        .frame(height: height)
    }
}

// MARK: - AppTextField
struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(Color.appTextInactive)
                    .frame(width: 20)
            }
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundColor(Color.appTextPrimary)
        }
        .padding(14)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appDivider, lineWidth: 1))
    }
}

// MARK: - Gauge Arc
struct GaugeArc: View {
    let value: Double
    let min: Double
    let max: Double
    let color: Color
    var lineWidth: CGFloat = 10

    private var progress: Double {
        guard max > min else { return 0 }
        return Swift.max(0, Swift.min(1, (value - min) / (max - min)))
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.1, to: 0.9)
                .stroke(color.opacity(0.15), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(90))
            Circle()
                .trim(from: 0.1, to: 0.1 + 0.8 * progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(90))
        }
    }
}

// MARK: - Toast
struct ToastView: View {
    let message: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.appTextPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Page control dots
struct PageDots: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i == current ? Color.appPrimary : Color.appDivider)
                    .frame(width: i == current ? 20 : 7, height: 7)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
            }
        }
    }
}
