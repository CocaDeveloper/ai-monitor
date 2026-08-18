import Combine
import Foundation
import ServiceManagement

@MainActor
public final class LaunchAtLoginController: ObservableObject {
    @Published public private(set) var isEnabled: Bool
    @Published public private(set) var message: String?

    public init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            isEnabled = enabled
            message = nil
        } catch {
            isEnabled = SMAppService.mainApp.status == .enabled
            message = "macOS could not change the login item. Check System Settings › General › Login Items."
        }
    }
}
