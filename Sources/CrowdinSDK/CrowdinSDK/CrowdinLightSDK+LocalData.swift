//
//  CrowdinLightSDK+LocalData.swift
//  CrowdinSDK
//

import Foundation

public extension CrowdinLightSDK {
    /// Stops the SDK and removes everything it persisted locally (downloaded strings, plurals,
    /// manifests, timestamps, etags, xcstrings, screenshots, and the related UserDefaults keys).
    ///
    /// - Safe to call when the SDK was never started: nothing is created on disk.
    /// - Idempotent.
    /// - The SDK can be started again in-process afterwards.
    /// - Call it on the thread you start the SDK on.
    class func removeAllLocalData() {
        stopIntervalUpdates()
        stop()
        ManifestManager.removeAllInMemoryManagers()
        removeCrowdinFolders()
        removeCrowdinUserDefaults()
    }

    private class func removeCrowdinFolders() {
        let name = (Bundle.main.bundleIdentifier ?? "") + CrowdinFolder.Strings.dot.rawValue + CrowdinFolder.Folders.crowdin.rawValue
        let fileManager = FileManager.default
        [FileManager.SearchPathDirectory.applicationSupportDirectory, .cachesDirectory]
            .compactMap { fileManager.urls(for: $0, in: .userDomainMask).first }
            .map { $0.path + CrowdinFolder.Strings.pathDelimiter.rawValue + name }
            .filter { fileManager.fileExists(atPath: $0) }
            .forEach { try? fileManager.removeItem(atPath: $0) }
    }

    private class func removeCrowdinUserDefaults() {
        let keys = [
            UserDefaults.Keys.customLocalization.rawValue,
            UserDefaults.Keys.mode.rawValue,
            "CrowdinSupportedLanguages.lastUpdatedDate",
            "CrowdinETagsKey"
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}
