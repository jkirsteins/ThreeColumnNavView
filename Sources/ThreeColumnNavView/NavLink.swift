//
//  NavLink.swift
//  NavigationViewTest
//
//  Created by Janis Kirsteins on 15/01/2022.
//

import SwiftUI

enum NavLinkMode {
    case push(_ column: UISplitViewController.Column)
    case set(_ column: UISplitViewController.Column)
}

/// NavLink maintains selection state, and communicates it to its label button through
/// the environment. The label button uses a button style wrapper, which reads this
/// environment value, and modifies the ButtonStyle invocation, and hooks into the right
/// NavLinkButtonStyle call (which takes the selection into account).
fileprivate struct NavLinkSelectedKey : EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    fileprivate var navLinkSelected: Bool {
        get {
            self[NavLinkSelectedKey.self]
        }
        set {
            self[NavLinkSelectedKey.self] = newValue
        }
    }
}

protocol NavLayer
{
    var navLinkState: NavLinkState { get }
    var destination: NavLinkDestination { get }
}

//@resultBuilder struct NavLinkDestinationBuilder {
//    static func buildBlock(_ items: NavigationItem...) -> NavigationState {
//        return NavigationState(title: nil, items: items)
//    }
//}

fileprivate struct InvalidationKey : EnvironmentKey {
    static let defaultValue = UUID()
}

extension EnvironmentValues {
    var invalidation: UUID {
        get {
            self[InvalidationKey.self]
        }
        set {
            self[InvalidationKey.self] = newValue
        }
    }
}

struct NavLinkDestination : View
{
    var wrapped: AnyView! = nil
    
    init<Content: View>(@ViewBuilder _ wrapped: ()->Content) {
        self.wrapped = AnyView(wrapped())
    }
    
    var body: some View {
        wrapped
    }
}

struct NavLink<Label> : NavLayer, View, Identifiable where Label : View {
    @Environment(\.navLinkId) var id: NavLinkId
    @Environment(\.navLinkState) var navLinkState
    
    var splitViewController: UISplitViewController? {
        return self.navLinkState.provider?.splitViewController
    }
    
    var targetColumn: UISplitViewController.Column? {
        switch(self.navLinkState.mode) {
        case .push(let column): return column
        case .set(let column): return column
        }
    }
    
    typealias ModifiedDestination = NavLinkDestination
    
    let labelProducer: () -> Label
    let destination: ModifiedDestination
    let navStateHolder = NavStateHolder()
    
    var labelText: String? = nil
    
    @State var isSelected = false
    
    class NavStateHolder
    {
        var desiredNavState: NavigationState? = nil
    }
    
    init<Destination: View>(
        @ViewBuilder destination: @escaping () -> Destination,
        @ViewBuilder label: @escaping () -> Label)
    {
        self.destination = NavLinkDestination(destination)
        self.labelProducer = label
    }
    
    init<Destination: View>(_ label: String, @ViewBuilder destination: @escaping () -> Destination) where Label == Text {
        self.init(destination: destination) {
            Text(label)
        }
        
        self.labelText = label
    }
    
    var body: some View {
        let innerBody = self.body_notListening.environment(\.navLinkSelected, isSelected)
        
        let selectionPublisher: Published<NavLinkId?>.Publisher?
        
        switch (self.navLinkState.currentColumn) {
        case .primary:
            selectionPublisher = self.navLinkState.provider?.primarySelection
        case .supplementary:
            selectionPublisher = self.navLinkState.provider?.supplementarySelection
        default:
            selectionPublisher = nil
        }
        
        guard let selectionPublisher = selectionPublisher else {
            return AnyView(innerBody)
        }
        
        return AnyView(innerBody.onReceive(selectionPublisher) { selectedId in
            guard self.isSelected != (self.id == selectedId) else { return }
            self.isSelected = selectedId == self.id
        })
    }
    
    @Environment(\.primaryButtonStyle) var primaryButtonStyle: AnyNavLinkButtonStyle
    @Environment(\.supplementaryButtonStyle) var supplementaryButtonStyle: AnyNavLinkButtonStyle
    
    struct StyleWrapper<T>: ButtonStyle where T: NavLinkButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            return wrapped.makeBody(configuration: configuration, selected: selected)
        }
        
        @Environment(\.navLinkSelected) var selected: Bool
        
        let wrapped: T
        
        init(_ wrapped: T) {
            self.wrapped = wrapped
        }
    }
    
    var body_notListening: some View {
        let button = Button(action: self.tappedSidebar, label: self.labelProducer)
            .listRowInsets(EdgeInsets())
        
        switch(currentColumn, isCompact) {
        case (.primary, false): //, (.compact, _):
            // If you add any VStacks or other decorations, it'll mess up the paddings (horizontal/vertical
            return AnyView(button.buttonStyle(StyleWrapper(primaryButtonStyle)))
        default:
            return AnyView(button.buttonStyle(StyleWrapper(supplementaryButtonStyle)))
        }
    }
    
    var currentColumn: UISplitViewController.Column {
        self.navLinkState.currentColumn
    }
    
    var isCompact: Bool {
        return self.navLinkState.isCompact
    }
    
    func tappedSidebar() {
        
        guard let provider = self.navLinkState.provider else {
            print("No coordinator available.")
            return
        }
        
        /*
         * State is not mirrored between compact/primary+supplementary modes.
         *
         * We need a way to track which column to set for, when in compact mode.
         * And we need a way to propogate the states from one mode to the other.
         */
        provider.markSelected(self.id, for: self.currentColumn)
        
        let childState: NavLinkState
        
        if self.isCompact {
            // compact mode doesn't change anything for children
            childState = self.navLinkState
        } else {
            let childMode: NavLinkMode
            if self.targetColumn == .primary {
                childMode = .set(.supplementary)
            } else if self.targetColumn == .supplementary {
                childMode = .set(.secondary)
            } else if self.targetColumn == .compact {
                childMode = .push(.compact)
            } else {
                childMode = .push(.secondary)
            }
            
            childState = NavLinkState(
                provider: provider,
                mode: childMode)
        }
        
        provider.activate(self, from: self.navLinkState, to: childState)
    }
}
