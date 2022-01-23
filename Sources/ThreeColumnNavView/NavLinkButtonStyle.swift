import SwiftUI

struct AnyNavLinkButtonStyle : NavLinkButtonStyle {

    let _makeBody: (ButtonStyleConfiguration, Bool)->AnyView
    
    @ViewBuilder
    func makeBody(configuration: ButtonStyleConfiguration, selected: Bool) -> AnyView {
        _makeBody(configuration, selected)
    }
    
    init<T>(_ wrapped: T) where T: NavLinkButtonStyle {
        self._makeBody = { AnyView(wrapped.makeBody(configuration: $0, selected: $1)) }
    }
    
}

private struct HostPrimaryColumnButtonStyleOverrideKey: EnvironmentKey {
    typealias Value = AnyNavLinkButtonStyle

    static let defaultValue: AnyNavLinkButtonStyle = AnyNavLinkButtonStyle(NavLinkStyleSidebar())
}

private struct HostSupplementaryColumnButtonStyleOverrideKey: EnvironmentKey {
    typealias Value = AnyNavLinkButtonStyle

    static let defaultValue: AnyNavLinkButtonStyle = AnyNavLinkButtonStyle(NavLinkStyleList())
}

struct _ButtonStyleToNavLinkButtonStyle : NavLinkButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration, selected: Bool) -> some View {
        return _makeBody(configuration)
    }
    
    let _makeBody: (ButtonStyleConfiguration)->AnyView
    
    init<T>(_ wrapped: T) where T: ButtonStyle {
        self._makeBody = { AnyView(wrapped.makeBody(configuration: $0)) }
    }
}

struct _NavLinkButtonStyleToButtonStyle : ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        return _makeBody(configuration)
    }
    
    let _makeBody: (ButtonStyleConfiguration)->AnyView
    
    init<T>(_ wrapped: T) where T: NavLinkButtonStyle {
        self._makeBody = { AnyView(wrapped.makeBody(configuration: $0, selected: false)) }
    }
}

extension EnvironmentValues {
    var primaryButtonStyle: AnyNavLinkButtonStyle {
        get {
            self[HostPrimaryColumnButtonStyleOverrideKey.self]
        }
        set {
            self[HostPrimaryColumnButtonStyleOverrideKey.self] = newValue
        }
    }
    
    var supplementaryButtonStyle: AnyNavLinkButtonStyle {
        get {
            self[HostSupplementaryColumnButtonStyleOverrideKey.self]
        }
        set {
            self[HostSupplementaryColumnButtonStyleOverrideKey.self] = newValue
        }
    }
}

extension View {

    func buttonStyle<T>(_ style: T, for column: UISplitViewController.Column) -> some View where T: ButtonStyle {
        return self.buttonStyle(_ButtonStyleToNavLinkButtonStyle(style), for: column)
    }
    
    func buttonStyle<T>(_ style: T, for column: UISplitViewController.Column) -> some View where T: NavLinkButtonStyle {
        switch(column) {
        case .primary:
            return self.environment(\.primaryButtonStyle, AnyNavLinkButtonStyle(style))
        case .supplementary:
            return self.environment(\.supplementaryButtonStyle, AnyNavLinkButtonStyle(style))
        default:
            fatalError("Button style override not implemented for column \(String(describing: column))")
    }
  }
}

