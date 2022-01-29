# ThreeColumnNavView

A description of this package.

## Known issues

- destination view modifiers can be invoked multiple times 
  when transitioning between views. 

  E.g. `onAppear` can be invoked twice on the target view, when 
  clicking on a NavLink in compact view.
  