import SwiftUI

public struct NavigationState : Equatable {
    internal init(title: String? = nil, items: [NavigationItem]? = nil) {
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
      
    var title: String?
    var items: [NavigationItem]?
}

struct NavigationStatePreferenceKey: PreferenceKey {
    static var defaultValue: NavigationState?
    
    static func reduce(value: inout NavigationState?, nextValue: () -> NavigationState?) {
        value = nextValue()
    }
}

/// Allows initializing navigation state by passing in multiple instances of `NavigationItem`.
@resultBuilder public struct NavigationStateBuilder {
    static func buildBlock(_ title: String, _ items: NavigationItem...) -> NavigationState {
        return NavigationState(title: title, items: items)
    }
    
    static func buildBlock(_ items: NavigationItem...) -> NavigationState {
        return NavigationState(title: nil, items: items)
    }
    
    static func buildExpression(_ expression: NavigationItem) -> NavigationItem {
        return expression
    }
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
    
    public func navigationState(title: String, @NavigationStateBuilder _ buildState: @escaping ()->NavigationState) -> some View {
        var state = buildState()
        state.title = title
        return self
            .preference(key: NavigationStatePreferenceKey.self, value: state)
    }
    
    func navigationState(@NavigationStateBuilder _ buildState: @escaping ()->NavigationState) -> some View {
        return self
            .preference(key: NavigationStatePreferenceKey.self, value: buildState())
    }
}
