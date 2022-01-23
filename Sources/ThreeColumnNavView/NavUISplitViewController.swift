import SwiftUI

class NavUISplitViewController<Content: View> : UISplitViewController
{
    let swiftUiView: NavView_Internal<Content>
    
    init(style: UISplitViewController.Style, view: NavView_Internal<Content>) {
        self.swiftUiView = view
        super.init(style: style)
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
