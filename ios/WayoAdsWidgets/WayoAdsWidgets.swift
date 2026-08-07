import WidgetKit
import SwiftUI

/// Shared sanitized snapshot keys (must match Flutter WayoAdsHomeWidgetConstants).
enum WayoAdsWidgetKeys {
    static let appGroup = "group.ma.wayo.wayoadsgo"
    static let authState = "auth_state"
    static let primaryLabel = "primary_metric_label"
    static let primaryValue = "primary_metric_value"
    static let leftLabel = "secondary_left_label"
    static let leftValue = "secondary_left_value"
    static let rightLabel = "secondary_right_label"
    static let rightValue = "secondary_right_value"
    static let staleHint = "stale_hint"
    static let statusMessage = "status_message"
    static let balance = "balance"
    static let pending = "pending_balance"
    static let currency = "currency"
    static let role = "role"
}

struct WayoAdsWidgetEntry: TimelineEntry {
    let date: Date
    let authState: String
    let statusMessage: String
    let primaryLabel: String
    let primaryValue: String
    let leftLabel: String
    let leftValue: String
    let rightLabel: String
    let rightValue: String
    let staleHint: String
    let balance: String
    let pending: String
    let currency: String
    let role: String

    var isLoggedIn: Bool { authState == "logged_in" }

    static var placeholder: WayoAdsWidgetEntry {
        WayoAdsWidgetEntry(
            date: Date(),
            authState: "logged_out",
            statusMessage: "Open Wayo to sign in",
            primaryLabel: "Active campaigns",
            primaryValue: "—",
            leftLabel: "Spend",
            leftValue: "—",
            rightLabel: "CTR",
            rightValue: "—",
            staleHint: "Updated —",
            balance: "",
            pending: "",
            currency: "USD",
            role: "advertiser"
        )
    }
}

struct WayoAdsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WayoAdsWidgetEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (WayoAdsWidgetEntry) -> Void) {
        completion(load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WayoAdsWidgetEntry>) -> Void) {
        let entry = load()
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func load() -> WayoAdsWidgetEntry {
        let defaults = UserDefaults(suiteName: WayoAdsWidgetKeys.appGroup)
        func s(_ key: String, _ fallback: String = "") -> String {
            defaults?.string(forKey: key) ?? fallback
        }
        return WayoAdsWidgetEntry(
            date: Date(),
            authState: s(WayoAdsWidgetKeys.authState, "logged_out"),
            statusMessage: s(WayoAdsWidgetKeys.statusMessage, "Open Wayo to sign in"),
            primaryLabel: s(WayoAdsWidgetKeys.primaryLabel, "Performance"),
            primaryValue: s(WayoAdsWidgetKeys.primaryValue, "—"),
            leftLabel: s(WayoAdsWidgetKeys.leftLabel),
            leftValue: s(WayoAdsWidgetKeys.leftValue, "—"),
            rightLabel: s(WayoAdsWidgetKeys.rightLabel),
            rightValue: s(WayoAdsWidgetKeys.rightValue, "—"),
            staleHint: s(WayoAdsWidgetKeys.staleHint, "Updated —"),
            balance: s(WayoAdsWidgetKeys.balance),
            pending: s(WayoAdsWidgetKeys.pending),
            currency: s(WayoAdsWidgetKeys.currency, "USD"),
            role: s(WayoAdsWidgetKeys.role, "advertiser")
        )
    }
}

private let wayoOrange = Color(red: 0.957, green: 0.478, blue: 0.122)
private let wayoBg = Color(red: 0.039, green: 0.039, blue: 0.039)
private let wayoMuted = Color(red: 0.545, green: 0.565, blue: 0.627)

struct PerformanceWidgetView: View {
    var entry: WayoAdsWidgetEntry

    var body: some View {
        ZStack {
            wayoBg
            VStack(alignment: .leading, spacing: 8) {
                Text("Wayo Ads")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(wayoOrange)
                if entry.isLoggedIn {
                    Text(entry.primaryLabel)
                        .font(.caption2)
                        .foregroundStyle(wayoMuted)
                    Text(entry.primaryValue)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                    HStack(spacing: 8) {
                        metric(entry.leftLabel, entry.leftValue)
                        metric(entry.rightLabel, entry.rightValue)
                    }
                    Text(entry.staleHint)
                        .font(.caption2)
                        .foregroundStyle(wayoMuted)
                } else {
                    Text(entry.statusMessage.isEmpty ? "Open Wayo to sign in" : entry.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(wayoMuted)
                        .padding(.top, 12)
                }
            }
            .padding(14)
        }
        .widgetURL(URL(string: "wayoads://dashboard"))
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(wayoMuted)
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct WalletWidgetView: View {
    var entry: WayoAdsWidgetEntry

    var body: some View {
        ZStack {
            wayoBg
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.role == "creator" ? "Earnings" : "Wallet")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(wayoOrange)
                if entry.isLoggedIn {
                    let symbol = entry.currency.uppercased() == "EUR" ? "€" : "$"
                    Text(entry.balance.isEmpty ? "—" : "\(symbol)\(entry.balance)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    if !entry.pending.isEmpty {
                        Text("Pending \(symbol)\(entry.pending)")
                            .font(.caption2)
                            .foregroundStyle(wayoMuted)
                    } else {
                        Text(entry.staleHint)
                            .font(.caption2)
                            .foregroundStyle(wayoMuted)
                    }
                } else {
                    Text(entry.statusMessage.isEmpty ? "Open Wayo to sign in" : entry.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(wayoMuted)
                }
            }
            .padding(14)
        }
        .widgetURL(URL(string: "wayoads://wallet"))
    }
}

struct QuickActionsWidgetView: View {
    var entry: WayoAdsWidgetEntry
    private var isCreator: Bool { entry.role == "creator" }

    var body: some View {
        ZStack {
            wayoBg
            VStack(alignment: .leading, spacing: 10) {
                Text("Quick actions")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(wayoOrange)
                if entry.isLoggedIn {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        link(isCreator ? "Opportunities" : "Create", isCreator ? "wayoads://campaigns" : "wayoads://campaigns/create")
                        link("Campaigns", "wayoads://campaigns")
                        link(isCreator ? "Earnings" : "Analytics", isCreator ? "wayoads://wallet" : "wayoads://analytics")
                        link(isCreator ? "Analytics" : "Wallet", isCreator ? "wayoads://analytics" : "wayoads://wallet")
                    }
                } else {
                    Text(entry.statusMessage.isEmpty ? "Open Wayo to sign in" : entry.statusMessage)
                        .font(.footnote)
                        .foregroundStyle(wayoMuted)
                }
            }
            .padding(12)
        }
    }

    private func link(_ title: String, _ url: String) -> some View {
        Link(destination: URL(string: url)!) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct WayoAdsPerformanceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WayoAdsPerformanceWidget", provider: WayoAdsTimelineProvider()) { entry in
            PerformanceWidgetView(entry: entry)
        }
        .configurationDisplayName("Wayo Performance")
        .description("Campaign KPIs at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WayoAdsWalletWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WayoAdsWalletWidget", provider: WayoAdsTimelineProvider()) { entry in
            WalletWidgetView(entry: entry)
        }
        .configurationDisplayName("Wayo Wallet")
        .description("Available balance.")
        .supportedFamilies([.systemSmall])
    }
}

struct WayoAdsQuickActionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WayoAdsQuickActionsWidget", provider: WayoAdsTimelineProvider()) { entry in
            QuickActionsWidgetView(entry: entry)
        }
        .configurationDisplayName("Wayo Quick Actions")
        .description("Shortcuts into Wayo Ads.")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct WayoAdsWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WayoAdsPerformanceWidget()
        WayoAdsWalletWidget()
        WayoAdsQuickActionsWidget()
    }
}
