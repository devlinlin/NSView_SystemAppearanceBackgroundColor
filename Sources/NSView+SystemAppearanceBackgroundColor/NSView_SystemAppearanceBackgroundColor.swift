import AppKit
extension NSView {
    public enum DefaultBackgroundColorAppearance {
        case light, dark
    }
    
    private static var LightModeBackgroundColorKey: String = "LightModeBackgroundColorKey"
    private static var DarkModeBackgroundColorKey: String = "DarkModeBackgroundColorKey"
    private static var DynamicColorEnableKey: String = "DynamicColorEnableKey"
    private static var DefaultBackgroundColorAppearanceKey: String = "DefaultBackgroundColorAppearanceKey"
    
    /// Specify appearance background color as default NSView background color as default
    public var defaultBackgroundColorAppearance: DefaultBackgroundColorAppearance {
        get {
            return (objc_getAssociatedObject(self, &NSView.DefaultBackgroundColorAppearanceKey) as? DefaultBackgroundColorAppearance) ?? .light
        }
        set{
            objc_setAssociatedObject(self, &NSView.DefaultBackgroundColorAppearanceKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    /// A boolean value for whether auto  color change for system appearance enabled
    /// default is false
    public var isDynamicColorEnabled: Bool {
        get {
            return (objc_getAssociatedObject(self, &NSView.DynamicColorEnableKey) as? Bool) ?? false
        }
        set{
            objc_setAssociatedObject(self, &NSView.DynamicColorEnableKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    /// Configure the background color for light mode
    /// default is white
    public var lightModeBackgroundColor: NSColor {
        get {
            return (objc_getAssociatedObject(self, &NSView.LightModeBackgroundColorKey) as? NSColor) ?? NSColor.white
        }
        set{
            objc_setAssociatedObject(self, &NSView.LightModeBackgroundColorKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            if !isDarkMode || self.defaultBackgroundColorAppearance == .light {
                self.layer?.backgroundColor = newValue.cgColor
            }
        }
    }
    
    /// Configure the background color for dark mode
    /// default is black
    public var darkModeBackgroundColor: NSColor {
        get {
            return (objc_getAssociatedObject(self, &NSView.DarkModeBackgroundColorKey) as? NSColor) ?? NSColor.black
        }
        set {
            objc_setAssociatedObject(self, &NSView.DarkModeBackgroundColorKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            if isDarkMode || self.defaultBackgroundColorAppearance == .dark {
                self.layer?.backgroundColor = newValue.cgColor
            }
        }
    }
    
    
    /// Verify whether current system appearance is dark mode
    public var isDarkMode: Bool {
        get {
            if #available(OSX 10.14, *) {
                return self.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            }
            return false
        }
    }
    
    /// Swizzle NSView viewDidChangeEffectiveAppearance
    static func colorModeBackgroundColorSwizzle() {
        let _:() = {
            let originSelector = #selector(NSView.viewDidChangeEffectiveAppearance)
            let swizzleSelector = #selector(NSView.swizzle_viewDidChangeEffectiveAppearance)
            guard let originMethod = class_getInstanceMethod(NSView.self, originSelector),
                  let swizzleMethod = class_getInstanceMethod(NSView.self, swizzleSelector)
            else {
                return
            }
            let isMethodAleadyThere: Bool = class_addMethod(NSView.self, originSelector, method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod))
            if isMethodAleadyThere {
                class_replaceMethod(NSView.self, swizzleSelector, method_getImplementation(originMethod), method_getTypeEncoding(originMethod))
            } else {
                method_exchangeImplementations(originMethod, swizzleMethod)
            }
        }()
    }
    
    @objc func swizzle_viewDidChangeEffectiveAppearance(){
        swizzle_viewDidChangeEffectiveAppearance()
        if !self.isDynamicColorEnabled {
            return
        }
        if isDarkMode {
            self.layer?.backgroundColor = darkModeBackgroundColor.cgColor
        } else {
            self.layer?.backgroundColor = lightModeBackgroundColor.cgColor
        }
    }
}
