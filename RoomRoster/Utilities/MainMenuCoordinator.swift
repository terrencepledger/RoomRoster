import SwiftUI

final class MainMenuCoordinator: ObservableObject {
    @Published var selectedTab: MenuTab = .inventory
    @Published var pendingSale: Sale?
}
