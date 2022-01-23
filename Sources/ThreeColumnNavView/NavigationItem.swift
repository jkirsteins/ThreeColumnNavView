import SwiftUI

/// Navigation item title can consist of a string or an SF symbol.
public enum NavigationItemTitle : Equatable, Hashable {
    case string(_ value: String)
    case symbol(_ name: String, title: String)
}

/// Items that go in the navigation bar.
public enum NavigationItem : Equatable, Hashable
{
    public static func == (lhs: NavigationItem, rhs: NavigationItem) -> Bool {
        switch(lhs, rhs) {
        case (.textButton(let lt, _), .textButton(let rt, _)):
            return lt == rt
        case (.editButton(let lm, let li), .editButton(let rm, let ri)):
            // Not a good comparison (distinct binding modes can have the same wrapped value...)
            return lm.wrappedValue == rm.wrappedValue && li == ri
        case (.addButton, .addButton):
            return true
        case (.circleMenu(let titleL, let itemsL), .circleMenu(let titleR, let itemsR)):
            return titleL == titleR && itemsL.count == itemsR.count
        case (.navigationActionReplacingBackIfCompact(let lt, let lm, _), .navigationActionReplacingBackIfCompact(let rt, let rm, _)):
            // Not a good comparison (distinct binding modes can have the same wrapped value...)
            return lt == rt && lm.wrappedValue == rm.wrappedValue
        default:
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .textButton(let title, _):
            hasher.combine(1)
            hasher.combine(title)
        case .editButton(let editMode, let initial):
            hasher.combine(2)
            hasher.combine(editMode.wrappedValue)
            hasher.combine(initial)
        case .addButton:
            hasher.combine(3)
        case .circleMenu(let title, let items):
            hasher.combine(4)
            hasher.combine(title)
            hasher.combine(items)
        case .navigationActionReplacingBackIfCompact(let title, let mode, _):
            hasher.combine(5)
            hasher.combine(mode.wrappedValue)
            hasher.combine(title)
        }
    }
    
    
    case textButton(_ title: String, action: ()->())
    case editButton(_ mode: Binding<EditMode>, initial: Bool)
    case addButton
    case navigationActionReplacingBackIfCompact(_ title: NavigationItemTitle, mode: Binding<EditMode>, action: ()->())
    case circleMenu(_ title: String, items: [UIAction])
    
    public static func editButton(_ mode: Binding<EditMode>) -> NavigationItem {
        return .editButton(mode, initial: mode.wrappedValue.isEditing)
    }
    
    public static func circleMenu(items: [UIAction]) -> NavigationItem {
        return .circleMenu("", items: items)
    }
    
    var requestsBackHidden: Bool {
        switch(self) {
        case .navigationActionReplacingBackIfCompact(_, let mode, _):
            return mode.wrappedValue.isEditing
        default:
            return false
        }
    }
    
    var barButtonItem: UIBarButtonItem {
        switch(self) {
        case .navigationActionReplacingBackIfCompact(let title, _, let action):
            
            switch(title) {
            case .string(let titleString):
                let uiaction = UIAction(title: titleString) { _ in action() }
                return UIBarButtonItem(title: titleString, primaryAction: uiaction)
            case .symbol(let symbolName, let actionTitle):
                let uiaction = UIAction(title: actionTitle) { _ in action() }
                let config = UIImage.SymbolConfiguration(scale: .large)
                let image = UIImage(systemName: symbolName, withConfiguration: config)
                return UIBarButtonItem(image: image, primaryAction: uiaction)
            }
            
        case .circleMenu(let title, let items):
            let config = UIImage.SymbolConfiguration(scale: .large)
            let image = UIImage(systemName: "ellipsis.circle", withConfiguration: config)
            let menu = UIMenu(title: title, children: items)
            return UIBarButtonItem(image: image, menu: menu)
        case .textButton(let title, let action):
            let uiaction = UIAction(title: title) { _ in
                action()
            }
            return UIBarButtonItem(title: title, primaryAction: uiaction)
        case .editButton(let editMode, let isEditing):
            switch(isEditing) {
            case false:
                let action = UIAction(title: "Begin editing") { (action) in
                    editMode.wrappedValue = .active
                }

                return UIBarButtonItem(systemItem: .edit, primaryAction: action)
            default:
                let action = UIAction(title: "End editing") { (action) in
                    editMode.wrappedValue = .inactive
                }

                return UIBarButtonItem(systemItem: .done, primaryAction: action)
            }
        case .addButton:
            return UIBarButtonItem(systemItem: .add)
        }
    }
}
