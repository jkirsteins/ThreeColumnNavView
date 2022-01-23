import Foundation
import SwiftUI

public struct NavLinkStyleDummy: NavLinkButtonStyle {
    public func makeBody(configuration: ButtonStyleConfiguration, selected: Bool) -> some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                configuration.label
                Spacer()
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .listRowInsets(EdgeInsets())
        .foregroundColor(.red)
        .background(selected ? .green : .blue)
    }
}

public struct ButtonStyleDummy: ButtonStyle {
    let wrapped = NavLinkStyleDummy()
    
    public func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        wrapped.makeBody(configuration: configuration, selected: false)
    }
}

/*
 - Compact style needs something that has no selected highlight, but has press-background
 - Expanded style needs something that has selected highlight, but no press-background
 
 (Because in expanded-style the pressed will blend into selected on release
*/
struct NavLinkStyleList: NavLinkButtonStyle{
    public func makeBody(configuration: ButtonStyleConfiguration, selected: Bool) -> some View {
        
        let text: UIColor
        let chevron: UIColor
        let background: UIColor
        
        switch(selected, configuration.isPressed) {
        
        case (true, false):
            text = .white
            background = .systemBlue
            chevron = .white
        case (true, true):
            text = .white 
            background = .systemBlue
            chevron = .white
        case (false, false):
            text = .label
            background = .systemBackground
            chevron = .tertiaryLabel
        case (false, true):
            text = .secondaryLabel
            background = .systemBackground
            chevron = .tertiaryLabel
        }
        
        return VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                configuration.label.foregroundColor(Color(text))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(chevron))
                    .font(.system(size: 14, weight: .semibold))
//                    .offset(x: configuration.isPressed ? 3 : 0)
            }
            Spacer()
        }
        .padding(.horizontal)
//        .background(Color(configuration.isPressed ? .secondarySystemBackground : .systemBackground))
        .background(Color(background))
        .contentShape(Rectangle())
        .listRowInsets(EdgeInsets())
    }
    
}

public protocol NavLinkButtonStyle {
    associatedtype Body: View
    func makeBody(configuration: ButtonStyleConfiguration, selected: Bool) -> Body
}

public struct NavLinkStyleSidebar: NavLinkButtonStyle {
    public func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        return makeBody(configuration: configuration, selected: false)
    }
    
    public func makeBody(configuration: ButtonStyleConfiguration, selected: Bool) -> some View {
        
        let foreground: UIColor
        let background: UIColor
        
        switch(selected, configuration.isPressed) {
        
        case (true, false):
            foreground = .label
            background = .quaternarySystemFill
        case (true, true):
            foreground = .secondaryLabel
            background = .systemFill
        
        case (false, false):
            foreground = .label
            background = .clear
        case (false, true):
            foreground = .secondaryLabel
            background = .clear
        }
        
        let base = VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                configuration.label
                    .foregroundColor(Color(foreground))
                Spacer()
            }
            Spacer()
        }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .background(Color(background), in: RoundedRectangle(cornerRadius: 10))
            .listRowInsets(EdgeInsets())
                        
        return base

    }
    
}
