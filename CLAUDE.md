# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Swift Project Guidelines

This document outlines preferred conventions and practices for Swift projects.

## Package Management
- Always use exact versions for Swift packages.
- Always grab the latest stable version when adding new dependencies.

## General Swift Style
- Use the modern optional unwrap syntax:
  - `if let viewModel { ... }`
  - Not `if let viewModel = viewModel { ... }`

- Prefer key path syntax over closure shorthand:
  - `.filter(\.isFavorite)`  
  - Not `.filter { $0.isFavorite }`
  - `.map(\.title)`  
  - Not `.map { $0.title }`

## SwiftUI / UIKit Style
- Prefer dot syntax for modifiers:
  - `.buttonStyle(.plain)`
  - Not `.buttonStyle(PlainButtonStyle())`

- Prefer closure-based syntax for SwiftUI components:
  - `Button { /* action */ } label: { Text("Press Me") }`
  - Not `Button(action: { /* action */ }, label: { Text("Press Me") })`

- Prefer using `.frame(maxWidth: .infinity, alignment: .leading)` over inserting `Spacer()` for layout alignment.
  - Use `.trailing` if applicable.

- Use `NavigationStack` instead of `NavigationView` for navigation containers.

## Code Structure and MARK Placement
Every SwiftUI view should follow this order for clarity and consistency. View Models should be similar just without the Body and Views:

1. **Variables**  
   - Public or private properties.  

2. **Initializer**  
   - Custom `init` to set variables.  
   - Precede with `// MARK: - Initializer`.

3. **Body**  
   - The SwiftUI `body` property.  
   - Precede with `// MARK: - Body`.

4. **Private Views**  
   - Small reusable subviews declared as private functions or computed properties.  
   - Precede with `// MARK: - Private Views`.

5. **Public Helpers**  
  - Public methods for formatting, transformations, or other business logic.  
  - Precede with `// MARK: - Public Helpers`.

6. **Private Helpers**  
   - Supporting methods for formatting, transformations, or other business logic.  
   - Precede with `// MARK: - Private Helpers`.

### Example SwiftUI View

```swift
import SwiftUI

struct QuotesView: View {
    private let quotes: [String]

    // MARK: - Initializer

    init(quotes: [String]) {
        self.quotes = quotes
    }

    // MARK: - Body

    var body: some View {
        List(quotes, id: \.self) { quote in
            QuoteRow(quote: quote)
        }
    }

    // MARK: - Private Views

    private func QuoteRow(quote: String) -> some View {
        Text(quote)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Private Helpers
    
    private func formattedQuote(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

## Testing
- Write all new tests using the SwiftTesting format.
- Do not create new XCTestCase-based tests.
- When migrating old tests, prefer converting to SwiftTesting where feasible.

## Project Organization
- Maintain a `Features.md` file to track major features.
  - If `Features.md` does not exist, create it.
  - Each entry should include:
    - Feature title
    - Brief description
- Use clear, descriptive commit messages.
- Document architectural decisions when possible.

## SFSymbols
- Use [SFSymbols library](https://github.com/Rspoon3/SFSymbols).
  - If not already being used, add the package to the project.
- Follow its recommended usage:
  - `Button(symbol: .sunset) { }`
  - `Image(symbol: .playCircle)`
  - `Label("Sunset", symbol: .sunset)`

## View Models
- Create a **dedicated view model** for each major view or screen.
- View models should:
  - Own the business logic for the view.
  - Expose state in a clean, testable way.
  - Keep the view focused on presentation only.
- Use `@Observable` (or `@StateObject` / `@ObservedObject` where appropriate) to bind state to views.
- Avoid placing heavy logic directly in SwiftUI view files.

## File and Folder Organization
- Each object (`struct`, `enum`, `class`, or `actor`) should live in its own file.
- Organize related files into folders for clarity.
- Views and their corresponding view models should be grouped together:
  - Example: `QuotesView` and `QuotesViewModel` live in a folder named `QuotesView`.

## Documentation
- Add lightweight **DocC comments** (`///`) to functions, properties, and objects when creating them.
- Focus on summarizing purpose and usage, not implementation details.
- Example:
  ```swift
  /// Creates a new `QuotesView`.
  /// - Parameters:
  ///   - quotes: The list of quotes to display.
  ///   - viewModel: An optional view model for providing extra data.
  init(quotes: [String], viewModel: QuotesViewModel? = nil) { ... }

  /// Formats a quote by trimming whitespace and newlines.
  /// - Parameter text: The raw quote text.
  /// - Returns: A cleaned-up string with whitespace removed.
  private func formattedQuote(_ text: String) -> String
  ```