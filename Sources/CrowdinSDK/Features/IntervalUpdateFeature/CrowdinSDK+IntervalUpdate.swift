//
//  CrowdinSDK+IntervalUpdate.swift
//  CrowdinSDK
//
//  Created by Serhii Londar on 6/1/19.
//

import Foundation

extension CrowdinLightSDK {
    class func startIntervalUpdates(interval: TimeInterval) {
        IntervalUpdateFeature.shared = IntervalUpdateFeature(interval: interval)
        IntervalUpdateFeature.shared?.start()
    }

    class func stopIntervalUpdates() {
        IntervalUpdateFeature.shared?.stop()
        IntervalUpdateFeature.shared = nil
    }

    func initializeIntervalUpdateFeature() {
        guard let config = CrowdinLightSDK.config else { return }
        if config.intervalUpdatesEnabled {
            if let interval = config.localizationUpdatesInterval {
                IntervalUpdateFeature.shared = IntervalUpdateFeature(interval: interval)
            } else {
                IntervalUpdateFeature.shared = IntervalUpdateFeature()
            }
            IntervalUpdateFeature.shared?.start()
        }
    }
}
