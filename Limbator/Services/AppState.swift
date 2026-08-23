import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {

    @Published var isOnboarded: Bool {
        didSet { UserDefaults.standard.set(isOnboarded, forKey: Keys.isOnboarded) }
    }

    @Published var micGranted: Bool {
        didSet { UserDefaults.standard.set(micGranted, forKey: Keys.micGranted) }
    }

    @Published var selectedTab: MainTab = .home
    @Published var presentedTutor: Bool = false

    private enum Keys {
        static let isOnboarded = "limb.isOnboarded"
        static let micGranted  = "limb.micGranted"
    }

    init() {
        let defaults = UserDefaults.standard
        isOnboarded = defaults.bool(forKey: Keys.isOnboarded)
        micGranted  = defaults.bool(forKey: Keys.micGranted)
    }

    enum MainTab: Hashable {
        case home, lessons, orthographe, games, profile
    }
}
