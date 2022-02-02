import SwiftUI

fileprivate struct PlaceholderStateKey : EnvironmentKey {
    static var defaultValue: PlaceholderState = .hidden
}

public extension EnvironmentValues {
    var placeholderState: PlaceholderState {
        get { self[PlaceholderStateKey.self] }
        set { self[PlaceholderStateKey.self] = newValue }
    }
}

public enum PlaceholderState {
    case hidden
    case overSupplementaryAndSecondary
    case overSecondary
    
    fileprivate func getFrame(parent: CGRect, primary: CGFloat, supplementary: CGFloat) -> CGRect {
        switch(self) {
        case .hidden:
            return CGRect.zero
        case .overSupplementaryAndSecondary:
            return CGRect(
                x: primary + 1,
                y: 0,
                width: parent.size.width - primary - 2,
                height: parent.size.height)
        case .overSecondary:
            return CGRect(
                x: primary + supplementary + 2,
                y: 0,
                width: parent.size.width - primary - supplementary - 4,
                height: parent.size.height)
        }
    }
}

struct PlaceholderModifier: ViewModifier {
    
    let placeholderState: PlaceholderState
    
    init(_ state: PlaceholderState) {
        self.placeholderState = state
    }
    
    func body(content: Content) -> some View {
        content.environment(\.placeholderState, self.placeholderState)
    }
}

class NavUISplitViewController<Content: View, Placeholder: View> : UISplitViewController, UISplitViewControllerDelegate
{
    typealias SwiftUIView = NavView_Internal<Content, Placeholder>
    
    let swiftUiView: SwiftUIView
    let placeholder: Placeholder?
    let placeholderVc: UIViewController?
    
    var placeholderState: PlaceholderState = .overSupplementaryAndSecondary {
        didSet {
            self.refreshPlaceholder()
        }
    }
    
    init(style: UISplitViewController.Style, view: SwiftUIView, placeholder: Placeholder?) {
        self.swiftUiView = view
        self.placeholder = placeholder
        if let placeholder = placeholder {
            self.placeholderVc = UIHostingController(rootView: placeholder.modifier(PlaceholderModifier(self.placeholderState)))
        } else {
            self.placeholderVc = nil
        }
        super.init(style: style)
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.refreshPlaceholder()
    }
    
    func refreshPlaceholder() {
        var needsToHidePlaceholder = (self.placeholderState == .hidden)
        switch (self.traitCollection.horizontalSizeClass) {
        case .compact:
            needsToHidePlaceholder = true
        default:
            break
        }
            
        self.placeholderVc?.view.removeFromSuperview()
        
        
        if !needsToHidePlaceholder,
            let placeholder = self.placeholder,
            let hvc = self.placeholderVc as? UIHostingController<ModifiedContent<Placeholder, PlaceholderModifier>> {
            
            let newRect = placeholderState.getFrame(
                parent: self.view.frame,
                primary: self.primaryColumnWidth,
                supplementary: self.supplementaryColumnWidth)
            
            hvc.rootView = placeholder.modifier(PlaceholderModifier(placeholderState))
            
            self.view.addSubview(hvc.view)
            hvc.view.frame = newRect
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredDisplayMode = .twoBesideSecondary
        
        if let nc = self.viewController(for: .primary) as? UINavigationController {
            nc.navigationBar.prefersLargeTitles = true
        }
        
        if let nc = self.viewController(for: .compact) as? UINavigationController {
            nc.navigationBar.prefersLargeTitles = true
        }
    }
}
