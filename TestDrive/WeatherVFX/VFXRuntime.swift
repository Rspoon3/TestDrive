//
//  VFXRuntime.swift
//  TestDrive
//

import Foundation
import UIKit

/// Finds and loads Apple's private `VFX` engine and the Weather app's scene files at runtime.
///
/// `VFX.framework` is the particle and rendering engine the Weather app uses for its animated backgrounds, and
/// `WeatherUI.framework` holds the scene packages (for example `WeatherV136_Default_Background.vfx`). Neither is public.
/// Both are loaded by path with `Bundle.load()`, so no private symbol is linked, and the scene files are read in place
/// from the system, never copied into this project.
///
/// They load on iOS 27 and later (a device or a simulator) and on a Mac as a "Designed for iPad" app, where they live
/// under `/System/iOSSupport`. The iOS 26 simulators have the same files, but the scene's compiled shaders need Metal
/// language 4.1, so loading it there fails with "This library is using language version 4.1 which is not supported on
/// this OS". ``isAvailable`` is therefore `false` before iOS 27.
///
/// > Important: This is private API for testing only. Don't ship it.
enum VFXRuntime {

    // A simulator can see the host Mac's /System/iOSSupport files. Never use those
    // as a fallback: their scene packages do not match the simulator's VFX binary.
    private static let frameworkRoot: String? = {
        #if targetEnvironment(simulator)
        guard let root = ProcessInfo.processInfo.environment["SIMULATOR_ROOT"], !root.isEmpty else { return nil }
        return root + "/System/Library/PrivateFrameworks"
        #elseif targetEnvironment(macCatalyst)
        return "/System/iOSSupport/System/Library/PrivateFrameworks"
        #else
        return ProcessInfo.processInfo.isiOSAppOnMac
            ? "/System/iOSSupport/System/Library/PrivateFrameworks"
            : "/System/Library/PrivateFrameworks"
        #endif
    }()

    private static let vfxPaths = frameworkRoot.map { [$0 + "/VFX.framework"] } ?? []
    private static let weatherUIPaths = frameworkRoot.map { [$0 + "/WeatherUI.framework"] } ?? []

    // MARK: - Public Helpers

    /// Whether the VFX engine can be used here: iOS 27 or later, with the VFX classes loaded. Evaluated once, which is
    /// also when the frameworks are loaded.
    static let isAvailable: Bool = {
        guard #available(iOS 27.0, *) else { return false }

        for path in vfxPaths + weatherUIPaths {
            _ = Bundle(path: path)?.load()
        }

        return NSClassFromString("VFX.VFXScene") != nil && viewClass != nil
    }()

    /// macOS also has an AppKit class named VFXView. Never treat it as a UIKit view.
    static var viewClass: UIView.Type? {
        NSClassFromString("VFXView") as? UIView.Type
    }

    /// WeatherUI supplies this library when creating its scene load options.
    static var shaderLibraryURL: URL? {
        weatherUIPaths.lazy.compactMap { path in
            Bundle(path: path)?.url(forResource: "default", withExtension: "metallib")
        }.first
    }

    /// The location of one of Weather's scene packages.
    /// - Parameter name: The package name without its extension, such as `WeatherV136_Default_Background`.
    /// - Returns: The package's URL inside `WeatherUI.framework`, or `nil` if it isn't on this system.
    static func sceneURL(named name: String) -> URL? {
        for path in weatherUIPaths {
            guard let resources = Bundle(path: path)?.resourceURL else { continue }

            let url = resources.appendingPathComponent("VFX/\(name).vfx")
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        return nil
    }
}
