# Features

## Locks and Keys Pattern
A SwiftUI implementation of the locks and keys architectural pattern for managing object dependencies and state. The pattern uses factories to ensure compile-time safety when creating views that require specific dependencies (like a logged-in user), preventing undefined states and reducing reliance on optionals and global state.

Key components:
- **RootFactory**: Base factory that manages root-level dependencies and creates user-bound factories
- **UserBoundFactory**: Specialized factory that requires a valid User to be created, ensuring user-specific views always have access to user data
- **User Model**: Simple user model with id, name, and email
- **LoginView/LoginViewModel**: Handles user authentication and creates user-bound factories upon successful login
- **ProfileView/ProfileViewModel**: Displays user profile information (can only be created through UserBoundFactory)
- **SettingsView/SettingsViewModel**: Manages user settings (can only be created through UserBoundFactory)

The pattern demonstrates how to use factory methods as "locks" that can only be opened with the right "key" (in this case, a User object), ensuring more robust and predictable application architecture.
