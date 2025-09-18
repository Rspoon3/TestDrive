//
//  PhotoRankingViewModel.swift
//  TestDrive
//

import SwiftUI
import PhotosUI

@MainActor
class PhotoRankingViewModel: ObservableObject {
    @Published var selectedPhotos: [PhotoItem] = []
    @Published var isRanking = false
    @Published var currentComparison: (left: PhotoItem, right: PhotoItem)?
    @Published var totalComparisons = 0
    @Published var completedComparisons = 0
    @Published var rankingComplete = false
    @Published var canUndo = false

    private var allComparisons: [(PhotoItem, PhotoItem)] = []
    private var currentComparisonIndex = 0
    private var comparisonResults: [Bool] = []

    func loadPhotos(from items: [PhotosPickerItem]) async {
        selectedPhotos = []

        for (index, item) in items.enumerated() {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                // Try to get the filename from itemIdentifier, otherwise use a numbered default
                let filename = item.itemIdentifier ?? "Photo \(index + 1)"
                selectedPhotos.append(PhotoItem(image: image, filename: filename))
            }
        }

        if !selectedPhotos.isEmpty {
            startRanking()
        }
    }

    func loadPhotosFromFiles(urls: [URL]) async {
        selectedPhotos = []

        for url in urls {
            if let data = try? Data(contentsOf: url),
               let image = UIImage(data: data) {
                let filename = url.lastPathComponent
                selectedPhotos.append(PhotoItem(image: image, filename: filename))
            }
        }

        if !selectedPhotos.isEmpty {
            startRanking()
        }
    }

    func startRanking() {
        guard selectedPhotos.count > 1 else {
            rankingComplete = true
            return
        }

        isRanking = true
        rankingComplete = false
        completedComparisons = 0
        currentComparisonIndex = 0
        comparisonResults = []
        canUndo = false

        // Generate all comparison pairs needed for ranking
        generateAllComparisons()

        // Estimate total comparisons
        totalComparisons = allComparisons.count

        // Start with first comparison
        showNextComparison()
    }

    private func generateAllComparisons() {
        allComparisons = []
        let photos = selectedPhotos

        // Generate all pairs for bubble sort style comparisons
        // This allows us to have a predictable set of comparisons
        for i in 0..<photos.count {
            for j in (i + 1)..<photos.count {
                allComparisons.append((photos[i], photos[j]))
            }
        }
    }

    private func showNextComparison() {
        if currentComparisonIndex < allComparisons.count {
            let comparison = allComparisons[currentComparisonIndex]
            currentComparison = (comparison.0, comparison.1)
            canUndo = currentComparisonIndex > 0
        } else {
            // All comparisons done, calculate final ranking
            calculateFinalRanking()
        }
    }

    func selectPhoto(isLeft: Bool) {
        guard currentComparisonIndex < allComparisons.count else { return }

        // Store the result
        if currentComparisonIndex < comparisonResults.count {
            // Replacing an existing result (after undo)
            comparisonResults[currentComparisonIndex] = isLeft
            // Remove any results after this point
            comparisonResults = Array(comparisonResults.prefix(currentComparisonIndex + 1))
        } else {
            // Adding new result
            comparisonResults.append(isLeft)
        }

        completedComparisons = comparisonResults.count
        currentComparisonIndex += 1

        showNextComparison()
    }

    func undoLastComparison() {
        guard currentComparisonIndex > 0 else { return }

        currentComparisonIndex -= 1
        completedComparisons = max(0, completedComparisons - 1)

        showNextComparison()
    }

    private func calculateFinalRanking() {
        // Calculate win counts for each photo
        var winCounts: [PhotoItem: Int] = [:]

        for photo in selectedPhotos {
            winCounts[photo] = 0
        }

        // Count wins based on comparison results
        for (index, comparison) in allComparisons.enumerated() {
            guard index < comparisonResults.count else { break }

            let winner = comparisonResults[index] ? comparison.0 : comparison.1
            winCounts[winner, default: 0] += 1
        }

        // Sort photos by win count (descending)
        var sortedPhotos = selectedPhotos.sorted { photo1, photo2 in
            winCounts[photo1, default: 0] > winCounts[photo2, default: 0]
        }

        // Assign ranks
        for index in 0..<sortedPhotos.count {
            sortedPhotos[index].rank = index + 1
        }

        selectedPhotos = sortedPhotos
        currentComparison = nil
        isRanking = false
        rankingComplete = true
    }
}