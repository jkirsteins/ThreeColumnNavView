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

            hvc.rootView = placeholder.modifier(PlaceholderModifier(placeholderState))
            
            switch(self.placeholderState) {
            case .overSupplementaryAndSecondary:
                guard let suppVc = self.viewController(for: .supplementary),
                      suppVc.view.bounds.size != CGSize.zero else {
                    return
                }
                let suppOrigin = suppVc.view.convert(CGPoint.zero, to: self.view)
                self.view.addSubview(hvc.view)
                hvc.view.frame = CGRect(
                    x: suppOrigin.x,
                    y: 0,
                    width: self.view.frame.size.width - suppOrigin.x,
                    height: self.view.frame.size.height)
            case .overSecondary:
                guard let secVc = self.viewController(for: .secondary) else {
                    return
                }
                secVc.view.addSubview(hvc.view)
                hvc.view.frame = secVc.view.bounds
            case .hidden:
                break
            }
        }
    }
    
    /// For initial display, no other hookpoint appears to be able to set the placeholder.
    /// The column viewcontrollers have empty bounds before this.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.refreshPlaceholder()
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
