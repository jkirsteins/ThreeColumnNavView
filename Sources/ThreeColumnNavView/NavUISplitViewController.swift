import SwiftUI

class NavUISplitViewController<Content: View, Placeholder: View> : UISplitViewController, UISplitViewControllerDelegate
{
    typealias SwiftUIView = NavView_Internal<Content, Placeholder>
    
    let swiftUiView: SwiftUIView
    
    init(style: UISplitViewController.Style, view: SwiftUIView) {
        self.swiftUiView = view
        super.init(style: style)
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
