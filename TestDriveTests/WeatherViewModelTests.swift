//
//  WeatherViewModelTests.swift
//  TestDriveTests
//

import Testing
@testable import TestDrive

@MainActor
struct WeatherViewModelTests {
    @Test func changingSnowIntensityKeepsThePile() {
        let viewModel = WeatherViewModel()
        let pile = viewModel.snowPile

        viewModel.setSnowIntensity(.blizzard)

        #expect(viewModel.snowPile === pile)
    }

    @Test func returningToSnowStartsAnEmptyPile() {
        let viewModel = WeatherViewModel()
        let pile = viewModel.snowPile

        viewModel.setEffect(.rain)
        viewModel.setEffect(.snow)

        #expect(viewModel.snowPile !== pile)
    }

    @Test func switchingToRainKeepsThePileUntilSnowReturns() {
        let viewModel = WeatherViewModel()
        let pile = viewModel.snowPile

        viewModel.setEffect(.rain)

        #expect(viewModel.snowPile === pile)
    }

    @Test func eachEffectRemembersItsIntensity() {
        let viewModel = WeatherViewModel()

        viewModel.setSnowIntensity(.blizzard)
        viewModel.setEffect(.rain)
        viewModel.setRainIntensity(.downpour)
        viewModel.setEffect(.snow)

        #expect(viewModel.snowIntensity == .blizzard)
        #expect(viewModel.rainIntensity == .downpour)
    }
}
