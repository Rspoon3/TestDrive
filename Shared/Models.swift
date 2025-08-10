import Foundation
import SwiftData

@Model
final class TimerFolder {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    var sortOrder: Int
    
    @Relationship(deleteRule: .cascade, inverse: \TimerItem.folder)
    var timers: [TimerItem]
    
    init(name: String, colorHex: String = "#E8B4A5", sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.timers = []
    }
}

@Model
final class TimerItem {
    var id: UUID
    var name: String
    var duration: TimeInterval
    var colorHex: String
    var soundName: String
    var createdAt: Date
    var sortOrder: Int
    
    var folder: TimerFolder?
    
    init(name: String, duration: TimeInterval, colorHex: String = "#D4A373", soundName: String = "Gentle") {
        self.id = UUID()
        self.name = name
        self.duration = duration
        self.colorHex = colorHex
        self.soundName = soundName
        self.createdAt = Date()
        self.sortOrder = 0
    }
}

enum TimerSound: String, CaseIterable {
    case gentle = "Gentle"
    case bell = "Bell"
    case chime = "Chime"
    case zen = "Zen"
    case soft = "Soft"
    case wave = "Wave"
    
    var systemSound: String {
        switch self {
        case .gentle: return "glass"
        case .bell: return "bell"
        case .chime: return "chime"
        case .zen: return "bloom"
        case .soft: return "morse"
        case .wave: return "sonar"
        }
    }
}