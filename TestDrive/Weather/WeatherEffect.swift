//
//  WeatherEffect.swift
//  TestDrive
//

/// Which weather overlay is showing.
enum WeatherEffect: String, CaseIterable, Identifiable {
    case off = "Off"
    case snow = "Snow"
    case rain = "Rain"

    var id: String { rawValue }
}
