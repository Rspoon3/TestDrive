//
//  RootFactory.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import Foundation

/// Root factory that manages base-level dependencies and creates user-bound factories.
@Observable
class RootFactory {

    // MARK: - Public Helpers

    /// Creates a user-bound factory using the provided user as a key.
    /// - Parameter user: The user to bind the factory to.
    /// - Returns: A factory that can create user-specific views and view models.
    func makeUserBoundFactory(for user: User) -> UserBoundFactory {
        UserBoundFactory(user: user, rootFactory: self)
    }

    /// Creates a login view model.
    /// - Returns: A new login view model instance.
    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(factory: self)
    }
}
