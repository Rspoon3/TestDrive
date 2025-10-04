//
//  UIViewController+Swizzle.swift
//  TestDrive
//

import UIKit

extension UIViewController {
    /// Swizzles the present method to trigger haptic feedback when a view controller is presented.
    static func swizzlePresentMethod() {
        let originalSelector = #selector(present(_:animated:completion:))
        let swizzledSelector = #selector(swizzled_present(_:animated:completion:))

        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc private func swizzled_present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        // Trigger haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Call the original method
        swizzled_present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
