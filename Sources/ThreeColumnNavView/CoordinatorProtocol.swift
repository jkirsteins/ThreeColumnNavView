import SwiftUI

protocol CoordinatorProtocol : AnyObject
{
    var splitViewController: UISplitViewController? { get }
    
    var primarySelection: Published<NavLinkId?>.Publisher { get }
    var supplementarySelection: Published<NavLinkId?>.Publisher { get }
    
    func markSelected(_ id: NavLinkId, for column: UISplitViewController.Column)
    
    func activate<L>(
        _ sender: NavLink<L>,
        from src: NavLinkState,
        to dst: NavLinkState)
    func pop()
}
