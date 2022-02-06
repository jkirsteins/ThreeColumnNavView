import SwiftUI

public struct NavigationState : Equatable {
    internal init(title: NavigationTitle? = nil, items: [NavigationItem]? = nil) {
        self.title = title
        self.items = items
    }
    
    internal init(item: NavigationItem) {
        self.init(title: nil, items: [item])
    }
    
    var isEditing: Bool {
        for item in (self.items ?? []) {
            if case .editButton(_, let isEditing) = item {
                return isEditing
            }
        }
        
        return false
    }
      
    var title: NavigationTitle?
    var items: [NavigationItem]?
}

struct NavigationStatePreferenceKey: PreferenceKey {
    static var defaultValue: NavigationState? = nil
    
    static func reduce(value: inout NavigationState?, nextValue: () -> NavigationState?) {
        
        /* Ignore the value if a 'nil' (default value?) is propogated up from deeper in the hierarchy */
        if let nextVal = nextValue() {
            value = nextVal
        }
    }
}

/// Allows initializing navigation state by passing in multiple instances of `NavigationItem`.
@resultBuilder public struct NavigationStateBuilder {
    public static func buildBlock(_ title: NavigationTitle, _ items: NavigationItem...) -> NavigationState {
        return NavigationState(title: title, items: items)
    }
    
    public static func buildBlock(_ items: NavigationItem...) -> NavigationState {
        return NavigationState(title: nil, items: items)
    }
    
    public static func buildExpression(_ expression: NavigationItem) -> NavigationItem {
        return expression
    }
}

public enum NavigationTitle : Equatable
{
    case inline(_ title: String)
    case large(_ title: String)
}

extension View {
    func recursiveViewToViewList<V0: View>(viewGroup: V0) -> [AnyView] {
        [AnyView(viewGroup)]
    }
    func recursiveViewToViewList<V0: View, V1: View>(viewGroup: TupleView<(V0,V1)>) -> [AnyView] {
        []
            + recursiveViewToViewList(viewGroup: viewGroup.value.0)
            + recursiveViewToViewList(viewGroup: viewGroup.value.1)
    }
    
    /// Initialize navigation bar title and the navigation bar controls.
    public func navigationState(title: NavigationTitle, @NavigationStateBuilder _ buildState: @escaping ()->NavigationState) -> some View {
        var state = buildState()
        state.title = title
        return self
            .preference(key: NavigationStatePreferenceKey.self, value: state)
    }
    
    /// Initialize a navigation bar with a title but no controls.
    public func navigationState(title: NavigationTitle) -> some View {
        let state = NavigationState(title: title, items: nil)
        return self
            .preference(key: NavigationStatePreferenceKey.self, value: state)
    }
    
    func navigationState(@NavigationStateBuilder _ buildState: @escaping ()->NavigationState) -> some View {
        return self
            .preference(key: NavigationStatePreferenceKey.self, value: buildState())
    }
}
