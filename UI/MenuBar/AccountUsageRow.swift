import SwiftUI

struct AccountUsageRow: View {
    let account: ProviderAccount
    let snapshot: UsageSnapshot?
    let showProgress: Bool
    let onRefresh: () -> Void
    let onConnect: () -> Void

    private var metric: UsageMetric? { snapshot?.primaryMetric }
    private var percent: Double? { metric?.remainingPercent }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                statusMark
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.displayName)
                        .pixelText(size: 14, weight: .semibold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    if let plan = account.planName {
                        Text(plan.capitalized).pixelText(size: 10).foregroundStyle(DesignTokens.muted)
                    }
                }
                Spacer(minLength: 12)
                Text(summary)
                    .pixelText(size: 13, weight: .semibold)
                    .foregroundStyle(summaryColor)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if showProgress, let percent { ProgressBlocks(percent: percent) }

            HStack(spacing: 6) {
                Image(systemName: resetIcon)
                    .font(.caption)
                Text(detail)
                    .pixelText(size: 10)
                Spacer()
                Button(action: actionableStatus ? onConnect : onRefresh) {
                    Image(systemName: actionableStatus ? "person.crop.circle.badge.plus" : "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .help(actionableStatus ? "Connect account" : "Refresh account")
                .accessibilityLabel(actionableStatus ? "Connect \(account.displayName)" : "Refresh \(account.displayName)")
            }
            .foregroundStyle(DesignTokens.muted)
        }
        .padding(.vertical, 9)
        .accessibilityElement(children: .combine)
    }

    private var statusMark: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(summaryColor)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(45))
            .accessibilityHidden(true)
    }

    private var summary: String {
        if account.status == .refreshing { return String(localized: "Refreshing…") }
        guard let metric else {
            return account.status == .notConnected ? String(localized: "Login required") : String(localized: "Usage unavailable")
        }
        if let percent = metric.remainingPercent { return UsageFormatters.percent(percent) }
        if let credits = metric.credits { return UsageFormatters.credits(credits) }
        if let used = metric.used, let limit = metric.limit { return "\(Int(used))/\(Int(limit)) \(metric.unit ?? "")" }
        return String(localized: "Usage unavailable")
    }

    private var detail: String {
        if account.status == .offline, let updated = snapshot?.updatedAt {
            return String(format: String(localized: "Offline · %@"), UsageFormatters.updated(updated).lowercased())
        }
        if actionableStatus { return account.status.userFacingText }
        return UsageFormatters.reset(metric?.windows.first(where: \ResetWindow.isPrimary)?.resetsAt)
    }

    private var resetIcon: String {
        account.status == .offline ? "wifi.slash" : actionableStatus ? "person.crop.circle" : "clock"
    }

    private var actionableStatus: Bool {
        [.notConnected, .loginCancelled, .loginFailed, .reconnectRequired].contains(account.status)
    }

    private var summaryColor: Color {
        if account.status == .offline || account.status == .unavailable { return DesignTokens.muted }
        if account.status == .notConnected || account.status == .loginFailed { return DesignTokens.danger }
        return DesignTokens.statusColor(remaining: percent)
    }
}
