//
//  EnvironmentValues+ArrangementSeparation.swift
//  TestDrive
//

import SwiftUI

extension EnvironmentValues {
    /// Whether the secondary view is shown beside the primary in a custom arrangement style.
    ///
    /// When `false` the primary is on its own, so it can hold the secondary's content itself.
    @Entry var isArrangementSeparated = false
}
