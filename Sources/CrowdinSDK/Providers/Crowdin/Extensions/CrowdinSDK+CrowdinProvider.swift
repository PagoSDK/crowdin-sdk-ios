//
//  CrowdinSDK+CrowdinProvider.swift
//  BaseAPI
//
//  Created by Serhii Londar on 05.12.2019.
//

import Foundation

public extension CrowdinLightSDK {
    /// Initialization method. Uses default CrowdinProvider with initialization values from Info.plist file.
    class func start() {
        self.startWithConfig(CrowdinSDKConfig.config(), completion: { })
    }

    /// Initialization method. Uses default CrowdinProvider with initialization values from Info.plist file.
    /// - Parameter completion: Crowdin SDK library initialization completion.
    class func start(completion: @escaping () -> Void) {
        self.startWithConfig(CrowdinSDKConfig.config(), completion: completion)
    }

    /// Initialization method. Initialize CrowdinProvider with passed parameters.
    ///
    /// - Parameters:
    ///   - config: Crowdin SDK configuration object.
    ///   - completion: Crowdin SDK library initialization completion.
    class func startWithConfig(_ config: CrowdinSDKConfig, completion: @escaping () -> Void) {
        self.config = config
        let crowdinProviderConfig = config.crowdinProviderConfig ?? CrowdinProviderConfig()
        let localization = currentLocalization ?? Bundle.main.preferredLanguage
        let remoteStorage = CrowdinRemoteLocalizationStorage(localization: localization, config: crowdinProviderConfig)
        self.startWithRemoteStorage(remoteStorage, completion: completion)
    }

    /// Method. Add Log message callback.
    ///
    /// - Parameters:
    ///   - completion: Crowdin SDK Log message completion.
    internal class func setOnLogCallback(_ completion: @escaping CrowdinSDKLogMessage) {
        addLogMessageHandler(completion)
    }
}
