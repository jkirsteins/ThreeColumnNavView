import SwiftUI
import Combine

/// This UIHostingController subclass attempts to monitor the NavigationState preference key, and coordinate
/// its navigationItem based on it.
class NavigationStateHostingViewController<T: View> : UIHostingController<NavStateWrapperView<T>>
{
    var coordinator: CoordinatorProtocol? = nil
    
    // source of truth can't  be in nav view controller!
    var existingBinding: Binding<NavigationState?>! = nil
    
    var isDirty = true
    @Published var currentState: NavigationState? = nil 
    
    convenience init(rootView: T, coordinator: CoordinatorProtocol) {
        let dummy = NavStateWrapperView(wrapped: rootView, navState: .constant(nil))
        self.init(rootView: dummy)
        
        self.existingBinding = Binding(
            get: { self.currentState },
            set: {
                self.currentState = $0
                
                self.isDirty = true
                self.reloadSwiftUIStateIfDirty(state: $0)
            }
        )
        
        self.wrappedRootView = rootView
        self.coordinator = coordinator
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            coordinator?.pop()
        }
    }
    
    var wrappedRootView: T {
        get {
            self.rootView.wrapped
        }
        set {
            self.rootView = NavStateWrapperView(wrapped: newValue, navState: existingBinding!)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /* Needed for e.g. pushes (so that the transition animation
        contains the right title */
        self.reloadSwiftUIStateIfDirty(state: currentState)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /* Needed for appearances without an animation (i.e. initial
         display */
        self.reloadSwiftUIStateIfDirty(state: currentState)
    }
    
    /// Initialize the navigationItem if the navigationstate is dirty.
    /// Has no effect if the state is not dirty.
    func reloadSwiftUIStateIfDirty(state: NavigationState?)
    {
        guard isDirty else { return }
        
        guard let state = state else {
            self.navigationItem.title = nil
            self.navigationItem.leftBarButtonItems = nil
            self.navigationItem.rightBarButtonItems = nil
            return
        }
        
        self.navigationItem.title = state.title
        
        var left: [UIBarButtonItem] = []
        var right: [UIBarButtonItem] = []
        
        navigationItem.leftItemsSupplementBackButton = true
        
        for item in (state.items ?? []) {
            self.placeSwiftUiItem(item, &left, &right, self.navigationItem)
        }
        
        self.navigationItem.leftBarButtonItems = left
        self.navigationItem.rightBarButtonItems = right
        
        isDirty = false
    }
    
    func placeSwiftUiItem(
        _ item: NavigationItem,
        _ left: inout [UIBarButtonItem],
        _ right: inout [UIBarButtonItem],
        _ navigationItem: UINavigationItem) {
        
        switch(item) {
        case .navigationActionReplacingBackIfCompact(_, let mode, _):
            if mode.wrappedValue.isEditing {
                left = [item.barButtonItem] + left
                navigationItem.leftItemsSupplementBackButton = false
            }
        case .addButton:
            right = right + [item.barButtonItem]
        case .editButton:
            right = right + [item.barButtonItem]
        case .circleMenu:
            right = right + [item.barButtonItem]
        case .textButton:
            right = [item.barButtonItem] + right
        }
    }
}
