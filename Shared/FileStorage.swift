//
//  FileStorage.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 8/4/25.
//


import Foundation
import OSLog
import CryptoKit

// MARK: - Protocols

public protocol FileManagerProtocol {
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]?) throws
    func fileExists(atPath path: String) -> Bool
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
    func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws
    func removeItem(at URL: URL) throws
    func moveItem(at srcURL: URL, to dstURL: URL) throws
}

public protocol URLSessionProtocol {
    func download(from url: URL, delegate: URLSessionTaskDelegate?) async throws -> (URL, URLResponse)
}

// MARK: - Protocol Conformances

extension FileManager: FileManagerProtocol {}

extension URLSession: URLSessionProtocol {}

/// A utility class for downloading and storing files locally with a configurable time-to-live (TTL).
///
/// This class stores files in a specified directory (e.g., Caches or Documents) and automatically
/// re-downloads them if they expire.
///
/// ### Example:
/// ```swift
/// let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("RiveAssets")
/// let fileStorage = try FileStorage(directory: folder, ttl: 14 * 24 * 60 * 60) // 2 weeks
/// let fileURL = try await fileStorage.fetchFile(from: URL(string: "https://example.com/file.riv")!)
/// ```
public final class FileStorage {
    private let storageDirectory: URL
    private let ttl: TimeInterval
    private let fileManager: FileManagerProtocol
    private let urlSession: URLSessionProtocol
    private let logger = Logger(subsystem: "com.yourcompany.FileStorage", category: "Storage")

    /// Initializes a new `FileStorage` instance.
    ///
    /// - Parameters:
    ///   - directory: The folder where files should be stored. This can be in `.cachesDirectory`, `.documentDirectory`, or any other valid location.
    ///   - ttl: Time-to-live (in seconds). Files older than this will be automatically replaced on the next access.
    ///   - fileManager: The file manager to use for file operations. Defaults to `FileManager.default`.
    ///   - urlSession: The URL session to use for downloads. If nil, creates an ephemeral session to avoid double caching.
    ///
    /// - Throws: An error if the storage directory could not be created.
    public init(
        directory: URL,
        ttl: TimeInterval,
        fileManager: FileManagerProtocol = FileManager.default,
        urlSession: URLSessionProtocol? = nil
    ) throws {
        self.storageDirectory = directory
        self.ttl = ttl
        self.fileManager = fileManager
        self.urlSession = urlSession ?? URLSession(configuration: .ephemeral)

        try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true, attributes: nil)
        logger.debug("Initialized FileStorage at directory: \(self.storageDirectory.path, privacy: .public) with TTL: \(ttl, privacy: .public) seconds")
    }
    
    /// Generates a unique filename for a URL using SHA256 hash while preserving file extension
    private func uniqueFilename(for url: URL) -> String {
        let urlString = url.absoluteString
        let hash = SHA256.hash(data: Data(urlString.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        // Preserve file extension if present
        let pathExtension = url.pathExtension
        if !pathExtension.isEmpty {
            return "\(hashString).\(pathExtension)"
        } else {
            return hashString
        }
    }

    /// Retrieves a file from local storage, downloading and caching it if needed.
    ///
    /// - Parameter url: The remote URL to download the file from.
    /// - Returns: A local `URL` pointing to the stored file.
    ///
    /// - Throws: Any file or network-related error that occurred during fetch or write.
    public func fetchFile(from url: URL) async throws -> URL {
        let fileName = uniqueFilename(for: url)
        var destinationURL = storageDirectory.appendingPathComponent(fileName)

        // If file exists and has the same name as requested, return it (regardless of TTL)
        if fileManager.fileExists(atPath: destinationURL.path) {
            // Update content access date to reset TTL
            var resourceValues = URLResourceValues()
            resourceValues.contentAccessDate = Date()
            try destinationURL.setResourceValues(resourceValues)
            logger.debug("Returning cached file: \(destinationURL.lastPathComponent, privacy: .public)")
            return destinationURL
        }

        logger.info("Downloading file from: \(url.absoluteString, privacy: .public)")
        let (tempURL, _) = try await urlSession.download(from: url, delegate: nil)

        do {
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            logger.info("Stored new file at: \(destinationURL.path, privacy: .public)")
            return destinationURL
        } catch {
            logger.error("Failed to store file: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// Clears all expired files in the storage directory based on the TTL.
    ///
    /// This method removes any files that have exceeded the configured TTL.
    public func clearExpiredFiles() async {
        let now = Date()
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: storageDirectory,
            includingPropertiesForKeys: [.contentAccessDateKey],
            options: []
        ) else {
            logger.warning("Failed to list contents of storage directory")
            return
        }
        
        for file in files {
            guard let resourceValues = try? file.resourceValues(forKeys: [.contentAccessDateKey]),
                  let accessDate = resourceValues.contentAccessDate,
                  now.timeIntervalSince(accessDate) > ttl else {
                continue
            }
            
            do {
                try fileManager.removeItem(at: file)
                logger.info("Removed expired file: \(file.lastPathComponent, privacy: .public)")
            } catch {
                logger.error("Failed to remove expired file: \(file.lastPathComponent, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
