import SwiftUI

public enum NavLinkId : Hashable, Equatable
{
    case none
    case uuid(_ : UUID)
    case string(_: String)
}

private struct NavLinkIdKey: EnvironmentKey {
    typealias Value = NavLinkId
    
    static let defaultValue: NavLinkId = .none
}

extension EnvironmentValues {
    var navLinkId: NavLinkId {
        get {
            self[NavLinkIdKey.self]
        }
        set {
            self[NavLinkIdKey.self] = newValue
        }
    }
}

extension View {
  public func id(_ navLinkId: NavLinkId) -> some View {
    environment(\.navLinkId, navLinkId)
  }
}
