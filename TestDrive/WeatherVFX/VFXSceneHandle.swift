//
//  VFXSceneHandle.swift
//  TestDrive
//

import Foundation
import ObjectiveC

/// A loaded private `VFXScene`, with typed access to its parameters.
///
/// A scene exposes its tunable values as named parameters on named objects. Weather's snow scene has about 280 of them,
/// almost all on the `MAIN` object: for example `snowFGParticleCount`, `rainBGParticleVelocity` and `lightningThickness`.
/// The framework checks the Swift type of each value and rejects an `NSNumber`, so values are written straight into the
/// parameter's storage through `withPointerToParameterOf:named:block:`. That makes the type your responsibility: use
/// ``setFloat(_:named:object:)`` only for `Float` parameters, ``setBool(_:named:object:)`` for `Bool` ones, and so on.
@MainActor
final class VFXSceneHandle {

    /// The scene that owns the effect and its simulation.
    let scene: NSObject

    /// The specific effect presented by the view, as in WeatherUI's renderer.
    let effect: NSObject

    // MARK: - Initializer

    /// Creates a scene and adds the package as an effect, matching WeatherUI's loading path.
    init?(sceneNamed name: String) {
        guard
            VFXRuntime.isAvailable,
            let url = VFXRuntime.sceneURL(named: name),
            let sceneClass = NSClassFromString("VFX.VFXScene") as? NSObject.Type,
            let optionsClass = (
                NSClassFromString("VFXSceneLoadOptions")
                    ?? NSClassFromString("_TtCC3VFX8VFXScene11LoadOptions")
            ) as? NSObject.Type
        else { return nil }

        let options = optionsClass.init()
        if let library = VFXRuntime.shaderLibraryURL {
            options.setValue(library, forKey: "metalLibraryURL")
        }

        // Keep alloc/init ownership explicit: init consumes the +1 alloc reference.
        let initializer = NSSelectorFromString("initWithOptions:")
        guard
            let implementation = class_getMethodImplementation(sceneClass, initializer),
            let allocated = sceneClass.perform(NSSelectorFromString("alloc"))
        else { return nil }
        typealias Initialize = @convention(c) (
            Unmanaged<AnyObject>, Selector, NSObject
        ) -> Unmanaged<AnyObject>?
        let initialize = unsafeBitCast(implementation, to: Initialize.self)
        guard let scene = initialize(allocated, initializer, options)?.takeRetainedValue() as? NSObject else {
            return nil
        }
        let selector = NSSelectorFromString("addEffectFrom:error:")
        guard scene.responds(to: selector), let implementation = scene.method(for: selector) else { return nil }
        typealias AddEffect = @convention(c) (
            AnyObject, Selector, NSURL, AutoreleasingUnsafeMutablePointer<NSError?>?
        ) -> AnyObject?
        var error: NSError?
        let addEffect = unsafeBitCast(implementation, to: AddEffect.self)
        guard let effect = addEffect(scene, selector, url as NSURL, &error) as? NSObject else {
            print("VFXSceneHandle: couldn't load \(url.lastPathComponent): \(String(describing: error))")
            return nil
        }
        self.scene = scene
        self.effect = effect
    }

    // MARK: - Public Helpers

    /// Pauses or resumes the scene's simulation.
    /// - Parameter isPaused: Whether to pause.
    func setPaused(_ isPaused: Bool) {
        scene.setValue(isPaused, forKey: "paused")
    }

    /// Writes a `Float` parameter.
    /// - Parameters:
    ///   - value: The new value.
    ///   - name: The parameter's name.
    ///   - object: The object that owns it.
    func setFloat(_ value: Float, named name: String, object: String = "MAIN") {
        withPointer(object: object, name: name) { pointer in
            pointer.assumingMemoryBound(to: Float.self).pointee = value
        }
    }

    /// Writes a `Bool` parameter.
    /// - Parameters:
    ///   - value: The new value.
    ///   - name: The parameter's name.
    ///   - object: The object that owns it.
    func setBool(_ value: Bool, named name: String, object: String = "MAIN") {
        withPointer(object: object, name: name) { pointer in
            pointer.assumingMemoryBound(to: Bool.self).pointee = value
        }
    }

    /// Writes a two-component parameter, such as a min and max.
    /// - Parameters:
    ///   - value: The new value.
    ///   - name: The parameter's name.
    ///   - object: The object that owns it.
    func setVector2(_ value: SIMD2<Float>, named name: String, object: String = "MAIN") {
        withPointer(object: object, name: name) { pointer in
            pointer.assumingMemoryBound(to: SIMD2<Float>.self).pointee = value
        }
    }

    /// Reads a `Float` parameter.
    /// - Parameters:
    ///   - name: The parameter's name.
    ///   - object: The object that owns it.
    /// - Returns: The current value.
    func float(named name: String, object: String = "MAIN") -> Float? {
        var result: Float?
        withPointer(object: object, name: name) { pointer in
            result = pointer.assumingMemoryBound(to: Float.self).pointee
        }
        return result
    }

    // MARK: - Private Helpers

    /// Calls `-[VFXEffect withPointerToParameterOf:named:block:]`, which runs the block synchronously with a pointer to
    /// the parameter's storage.
    private func withPointer(object: String, name: String, _ body: @escaping (UnsafeMutableRawPointer) -> Void) {
        typealias PointerAccess = @convention(c) (AnyObject, Selector, NSString, NSString, AnyObject) -> Void

        let selector = NSSelectorFromString("withPointerToParameterOf:named:block:")
        guard effect.responds(to: selector), let implementation = effect.method(for: selector) else { return }

        let block: @convention(block) (UnsafeMutableRawPointer) -> Void = { pointer in body(pointer) }
        let access = unsafeBitCast(implementation, to: PointerAccess.self)
        // The engine simulates on its own runtime thread. Main-actor isolation alone
        // doesn't protect its parameter storage while that thread is reading it.
        typealias Transaction = @convention(c) (AnyObject, Selector) -> Void
        let begin = NSSelectorFromString("beginTransaction")
        let end = NSSelectorFromString("endTransaction")
        guard scene.responds(to: begin), scene.responds(to: end),
              let beginIMP = scene.method(for: begin), let endIMP = scene.method(for: end) else { return }
        unsafeBitCast(beginIMP, to: Transaction.self)(scene, begin)
        defer { unsafeBitCast(endIMP, to: Transaction.self)(scene, end) }
        access(effect, selector, object as NSString, name as NSString, unsafeBitCast(block, to: AnyObject.self))
    }
}
