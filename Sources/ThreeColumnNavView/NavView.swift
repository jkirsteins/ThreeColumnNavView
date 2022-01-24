import SwiftUI
import Combine

struct NavLinkStateModifier : ViewModifier {
    let state: NavLinkState
    weak var vc: UIViewController?
    
    init(_ state: NavLinkState) {
        self.state = state
    }
    
    func body(content: Content) -> some View
    {
        let res = content
            .transformEnvironment(\.navLinkState) { instate in
                instate.selected = self.state.selected
                instate.mode = self.state.mode
                instate.provider = self.state.provider
            }
        if (self.state.isCompact) {
            // We need some hybrid of .sidebar (for collapsible headers) and .insetGrouped (for rest of appearance)
            return AnyView(res.listStyle(.insetGrouped))
        } else if (self.state.currentColumn == .primary) {
            return AnyView(res.listStyle(.sidebar))
        } else {
            return AnyView(res.listStyle(.plain))
        }
    }
}

extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

/// The root navigation view. Analogous to the SwiftUI `NavigationView` control,
/// except this will always have three columns.
public struct NavView<Content: View> : View {
    let root: NavView_Internal<Content>
    
    public init(@ViewBuilder sidebar: () -> Content) {
        self.root = NavView_Internal(sidebar: sidebar())
    }
    
    public var body: some View {
        self.root.edgesIgnoringSafeArea(.all)
    }
}

struct NavStateWrapperView<Content: View> : View {
    let wrapped: Content
    @Binding var navState: NavigationState?
    
    var body: some View {
        wrapped.onPreferenceChange(NavigationStatePreferenceKey.self, perform: {
            newState in
            self.navState = newState
        })
    }
}

class InternalUINavigationController : UINavigationController, UINavigationControllerDelegate
{
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
}

fileprivate struct NavStateBindingKey : EnvironmentKey {
    static let defaultValue: Binding<NavigationState?>? = nil
}

extension EnvironmentValues {
    public var navStateBinding: Binding<NavigationState?>? {
        get {
            self[NavStateBindingKey.self]
        }
        set {
            self[NavStateBindingKey.self] = newValue
        }
    }
}

struct NavView_Internal<Content: View>: UIViewControllerRepresentable {
    
    typealias NavigationVCImpl = InternalUINavigationController
    
    let sidebar: Content
    
    init(sidebar: Content) {
        self.sidebar = sidebar
    }
    
    class Coordinator : NSObject, CoordinatorProtocol {
        @Published var _primarySelection: NavLinkId? = nil
        @Published var _supplementarySelection: NavLinkId? = nil
        
        var parentObserver: NSKeyValueObservation?

        var primarySelection: Published<NavLinkId?>.Publisher {
            $_primarySelection
        }
        
        var supplementarySelection: Published<NavLinkId?>.Publisher {
            $_supplementarySelection
        }
        
        weak var splitViewController: UISplitViewController?
        
        func pop() {
            _ = navLayers.popLast()
        }
        
        var navLayers: [NavLayer] = []
        
        func activate<L>(
            _ sender: NavLink<L>,
            from state: NavLinkState,
            to dst: NavLinkState)
        {
            guard let svc = splitViewController else {
                return
            }
            
            let targetView = sender.destination.modifier(NavLinkStateModifier(dst))
            let vc: DestinationContentType = NavigationStateHostingViewController(
                rootView: targetView,
                coordinator: self)
            
            let targetVc: UIViewController
            if case .set(.secondary) = state.mode {
                targetVc = NavigationVCImpl(rootViewController: vc)
            } else {
                targetVc = vc
            }
            
            switch(state.mode) {
            case .set(let column):
                
                /* If we're setting a column, the navLayers need to be
                 reset to either 0,1 or 2 items */
                switch(column) {
                case .supplementary:
                    self.navLayers = [
                        sender
                        ]
                case .secondary:
                    self.navLayers = [
                        self.navLayers[0],
                        sender
                        ]
                default:
                    fatalError("Unexpected .set mode (\(column))")
                }
                
                // Visual change that shouldn't affect `navLayers`
                if column == .supplementary {
                    // We could keep track of what was here before?
                    let x = UIViewController()
                    x.view = UIView()
                    x.view.backgroundColor = UIColor.white
                    svc.setViewController(NavigationVCImpl(rootViewController: x), for: .secondary)
                }
                svc.setViewController(targetVc, for: column)
            case .push(let column):
                self.navLayers.append(sender)
                let candidate = svc.viewController(for: column)
                guard let nc = candidate as? NavigationVCImpl else {
                    fatalError("Invalid UIViewController for \(String(describing: column.rawValue)) (expected UINavigationController but got \(String(describing: candidate)))")
                }
                
                /* Hack to force the navstate to update before
                 we start the transition.
                 
                 Otherwise the title/navbar controls will flicker on after
                 the push animation is completed.*/
                targetVc.view.snapshotView(afterScreenUpdates: true)
                
                nc.pushViewController(targetVc, animated: true)
            }
        }
        
        func markSelected(_ id: NavLinkId, for column: UISplitViewController.Column)
        {
            switch(column) {
            case .primary:
                self._primarySelection = id
                
                // When changing primary selection, we clear the secondary column contents
                // If we don't clear supplementarySelection here, and switch away-then-back, we'll
                // end up with selection in the supplementary column, but empty secondary column.
                self._supplementarySelection = nil
            case .supplementary:
                self._supplementarySelection = id
            default:
                break
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    typealias SidebarContentType = NavigationStateHostingViewController<ModifiedContent<Content, NavLinkStateModifier>>
    typealias DestinationContentType = NavigationStateHostingViewController<ModifiedContent<NavLinkDestination, NavLinkStateModifier>>
    
    func makeUIViewController(context: Context) -> UISplitViewController {
        let result = NavUISplitViewController(style: .tripleColumn, view: self)
        
        let middle = UIHostingController(rootView: EmptyView())
        result.setViewController(middle, for: .supplementary)

        let suppl = UIHostingController(rootView: EmptyView())
        result.setViewController(suppl, for: .secondary)
        
        var primaryModifier = NavLinkStateModifier(
            NavLinkState(provider: context.coordinator, mode: .set(.supplementary))
        )
        let list = SidebarContentType(
            rootView: self.sidebar.modifier(primaryModifier),
            coordinator: context.coordinator)
        primaryModifier.vc = list
                
        let listNc = NavigationVCImpl(
            rootViewController: list)
        result.setViewController(listNc, for: .primary)
                
        let compactList = SidebarContentType(
            rootView: self.sidebar.modifier(NavLinkStateModifier(
                NavLinkState(provider: context.coordinator, mode: .push(.compact)))),
            coordinator: context.coordinator)
        
        // If we don't wrap this in NC, then we will have nothing to "push" child VC with
        let compactListNc = NavigationVCImpl(
            rootViewController: compactList)
        result.setViewController(compactListNc, for: .compact)
        
        context.coordinator.splitViewController = result
        
        return result
    }
    
    func updateUIViewController(_ uiViewController: UISplitViewController, context: Context) {
        // This is called on subsequent views
        
        // reset sidebar
        if let sidebarHost = uiViewController.viewController(for: .primary) as? SidebarContentType {
            // no NC wrapper
            sidebarHost.wrappedRootView = self.sidebar.modifier(
                NavLinkStateModifier(NavLinkState(provider: context.coordinator, mode: .set(.supplementary))))
        } else if let sidebarNc = uiViewController.viewController(for: .primary) as? NavigationVCImpl,
                  let sidebarHost = sidebarNc.viewControllers.first as? SidebarContentType {
            
            sidebarHost.wrappedRootView = self.sidebar.modifier(
                NavLinkStateModifier(NavLinkState(provider: context.coordinator, mode: .set(.supplementary))))
        } else {
            fatalError("Can't update")
        }
    
        if let compactNc = uiViewController.viewController(for: .compact) as? NavigationVCImpl {
            
            // Child views should take care of updating themselves, if we don't change at the root
            
            for (ix, childVc) in compactNc.viewControllers.enumerated() {
                
                if let compactVc = childVc as? SidebarContentType {
                    
                    guard ix == 0 else {
                        fatalError("SidebarContentType must have index 0")
                    }
                    
                    compactVc.wrappedRootView = self.sidebar.modifier(
                        NavLinkStateModifier(NavLinkState(provider: context.coordinator, mode: .push(.compact))))
                                        
                }
            }
            
        } else {
            fatalError("No compact to update")
        }
    }
}
