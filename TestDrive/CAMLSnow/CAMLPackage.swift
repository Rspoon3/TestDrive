//
//  CAMLPackage.swift
//  TestDrive
//

import QuartzCore

/// Loads Core Animation Markup Language (`.caml`) scenes.
///
/// CAML is the XML format Apple's own apps use to describe layer trees, including `CAEmitterLayer` particle systems
/// with emitter behaviors. Apple's Weather app used it for its backgrounds before iOS 15. Loading it goes through the
/// private `CAPackage` class, which is found by name at runtime, so no private symbol is linked. If the class is
/// missing, or the file can't be read, loading returns `nil` and nothing is shown.
///
/// > Important: This is private API, like the `CAEmitterBehavior` that EmitterBehaviors wraps. Don't ship it without a
/// > fallback or a flag.
enum CAMLPackage {

    /// `kCAPackageTypeCAMLFile`.
    private static let camlFileType = "com.apple.coreanimation-xml"

    // MARK: - Public Helpers

    /// Loads a `.caml` file from a bundle.
    /// - Parameters:
    ///   - name: The file name without its extension.
    ///   - bundle: The bundle that contains the file.
    /// - Returns: The scene's root layer, or `nil` if it couldn't be loaded.
    static func rootLayer(named name: String, in bundle: Bundle = .main) -> CALayer? {
        guard
            let url = bundle.url(forResource: name, withExtension: "caml"),
            let data = try? Data(contentsOf: url)
        else { return nil }

        return rootLayer(from: data)
    }

    /// Loads a scene from CAML data.
    /// - Parameter data: The contents of a `.caml` file.
    /// - Returns: The scene's root layer, or `nil` if it couldn't be loaded.
    static func rootLayer(from data: Data) -> CALayer? {
        guard
            let packageClass = NSClassFromString("CAPackage") as? NSObject.Type,
            case let selector = NSSelectorFromString("packageWithData:type:options:error:"),
            packageClass.responds(to: selector),
            let implementation = packageClass.method(for: selector)
        else { return nil }

        // `+packageWithData:type:options:error:` as a C function: (self, _cmd, data, type, options, error) -> package.
        typealias Loader = @convention(c) (
            AnyObject,
            Selector,
            NSData,
            NSString,
            NSDictionary?,
            AutoreleasingUnsafeMutablePointer<NSError?>?
        ) -> AnyObject?

        let load = unsafeBitCast(implementation, to: Loader.self)
        var error: NSError?

        guard let package = load(packageClass, selector, data as NSData, camlFileType as NSString, nil, &error) else {
            return nil
        }

        return package.value(forKey: "rootLayer") as? CALayer
    }
}
