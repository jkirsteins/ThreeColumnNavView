import SwiftUI

private struct NavLinkStateKey: EnvironmentKey {
    typealias Value = NavLinkState
    
    static let defaultValue: NavLinkState = NavLinkState.defaultValue
}

extension EnvironmentValues {
    var navLinkState: NavLinkState {
        get {
            self[NavLinkStateKey.self]
        }
        set {
            self[NavLinkStateKey.self] = newValue
        }
    }
}

struct NavLinkState {
    
    static var defaultValue: NavLinkState = {
        NavLinkState(provider: nil, mode: .set(.supplementary))
    }()
    
    private init(provider: CoordinatorProtocol?, mode: NavLinkMode) {
        self.provider = provider
        self.mode = mode
        self.selected = nil
    }
    
    var isCompact: Bool {
        switch(self.mode) {
        case .push(.compact):
            return true
        default:
            return false
        }
    }
    
    var currentColumn: UISplitViewController.Column {
        guard !self.isCompact else {
            return .compact
        }
        
        switch(self.mode) {
        case .set(.supplementary): return .primary
        case .set(.secondary): return .supplementary
        case .push(.secondary): return .secondary
        default:
            fatalError("Can't determine current column from \(self.mode)")
        }
    }
    
    weak var provider: CoordinatorProtocol?

    var selected: String?
    var mode: NavLinkMode
    
    init(provider: CoordinatorProtocol, mode: NavLinkMode) {
        self.mode = mode
        self.provider = provider
    }
}
