import SwiftUI

#if !DEBUG
    typealias AliasNavLink = NavigationLink
    typealias AliasNavView = NavigationView
#else
    typealias AliasNavLink = NavLink
    typealias AliasNavView = NavView
#endif

//class Test : Hashable, Equatable
//{
//    static func == (lhs: Test, rhs: Test) -> Bool {
//        lhs.uuid == rhs.uuid
//    }
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(self.uuid)
//    }
//
//    let uuid = UUID().uuidString
//    var editMode: EditMode = .inactive
//
//    var isEditing: Bool {
//        editMode.isEditing
//    }
//}

struct TestDestination : View
{
    class Holder
    {
        var editMode: EditMode = .inactive
    }
    
    let item: String
    
    @State var count: Int = 0
    @State var editMode: EditMode = .inactive
    
    var editMode2 = Holder()
    
    let rootCount: Binding<Int>
    
    init(_ item: String, rootCount: Binding<Int>) {
        self.item = item
        self.rootCount = rootCount
        print("INIT INIT")
    }
    
    var body: some View {
        VStack {
            List {
                Button("Inc: \(self.count)") {
                    self.count += 1
                    self.rootCount.wrappedValue += 1
                }
                
                Button("Internal test") {
                    self.editMode = (self.editMode == .active ? .inactive : .active)
                }
                
                if editMode == .inactive {
                    Text("Edit: inactive")
                } else {
                    Text("Edit: active")
                }
                
                Text(verbatim: "Root count: \(self.rootCount.wrappedValue)")
                
                ForEach(0..<3) { ix in
                    AliasNavLink(destination: {
                        Text("Hello \(item) child \(ix)")
                    }, label: {
                        Text("Hello \(item) \(ix)")
                    }).id(.string("\(item) \(ix)"))
                }
            }
        }
        .navigationState(title: "Middle \(item)") {
            NavigationItem.navigationActionReplacingBackIfCompact(.symbol("plus", title: "Create"), mode: self.$editMode) {
                self.count += 1
            }
            
            NavigationItem.editButton(self.$editMode)
        }
    }
}

@main
struct MyApp: App {
    @State var items = ["Red", "Green", "Blue"]
    
    @State var selected: String? = nil
    
    @State var count: Int = 0
    
    @ViewBuilder
    var testItems: some View {
        Text("Count: \(self.count)")
        Button("Inc") {
            self.count += 1
        }
        
        ForEach(self.$items, id: \.self) { $item in
            AliasNavLink(destination: {
                TestDestination(item, rootCount: $count)
            }, label: {
                Text("\(item)")
            }).id(.string(item))
        }
        
        Button("Shuffle") {
            self.items.shuffle()
        }
        
        Button("Add") {
            self.items.append(UUID().uuidString)
        }
        
        Button("Reset") {
            self.items = ["Red", "Green", "Blue"]
        }
    }
    
//    var body_simple: some Scene {
//        WindowGroup {
//            Text("Hello World").toolbarX(.navigationBarLeading) {
//                Button("Press Me") {
//                    print("Pressed")
//                }
//            }
//        }
//    }
//
    
    @State var navTitle = "Sidebar"
    @State var editMode: EditMode = .inactive
    
    var body: some Scene {
        
        return WindowGroup {
            AliasNavView {
                List(selection: self.$selected) {
                    
                    Section(header: Text("First section")) {
                        testItems
                    }
                    
                    Section(header: Text("Second section")) {
                        Button("Random title") {
                            self.navTitle = UUID().uuidString
                            print("Nav title", navTitle)
                        }
                        Text(self.navTitle)
                        
                        if editMode == .inactive {
                            Text("Edit: inactive")
                        } else {
                            Text("Edit: active")
                        }
                    }
                }
//                .navigationState(title: navTitle) {
////                    NavigationItem.editButton(self.$editMode)
//                }
                
                EmptyView()
                
                EmptyView()
            }
            .buttonStyle(NavLinkStyleSidebar(), for: .primary)
            .buttonStyle(NavLinkStyleList(), for: .supplementary)
        }
    }
    
    var body_off: some Scene {
        WindowGroup {
            AliasNavView {
                List {
                    AliasNavLink("Item 1") {
                        List {
                            AliasNavLink("Item 1.1") {
                                List {
                                    AliasNavLink("Item 1.1.1") {
                                        List {
                                            AliasNavLink("Item 1.1.1.1") {
                                                Text("Hello from 1.1.1.1")
                                            }
                                            AliasNavLink("Item 1.1.1.2") {
                                                Text("Hello from 1.1.1.2")
                                            }
                                        }
                                    }
                                    AliasNavLink("Item 1.1.2") {
                                        List {
                                            AliasNavLink("Item 1.1.2.1") {
                                                Text("Hello from 1.1.2.1")
                                            }
                                            AliasNavLink("Item 1.1.2.2") {
                                                Text("Hello from 1.1.2.2")
                                            }
                                        }
                                    }
                                }
                            }
                            AliasNavLink("Item 1.2") {
                                List {
                                    AliasNavLink("Item 1.2.1") {
                                        Text("Hello from 1.2.1")
                                    }
                                    AliasNavLink("Item 1.2.2") {
                                        Text("Hello from 1.2.2")
                                    }
                                }
                            }
                        }
                    }
                    
                    AliasNavLink("Hello 2") {
                        Text("Inside link 2")
                    }.listRowBackground(Ellipse()
                                            .background(Color.clear)
                                            .foregroundColor(.purple)
                                            .opacity(0.3)
                    )
                } //.listStyle(.sidebar)
                
                EmptyView()
                
                EmptyView()
            }
        }
    }
}
