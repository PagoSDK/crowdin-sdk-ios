//
//  Bundle+Swizzle.swift
//  CrowdinSDK (Pago fork)
//
//  Previously this file installed a process-wide method_exchangeImplementations
//  on NSBundle.localizedString(forKey:value:table:). That global swizzle was
//  also picked up by host applications' own NSLocalizedString calls — the
//  fallback path resolved against Crowdin's currentLocalization instead of the
//  device locale, visibly flipping language for any host with reactive text
//  bindings the moment our SDK initialised.
//
//  Interception is now scoped to PagoLocalizedBundle (see
//  PagoLocalizedBundle.swift). The class methods below remain only as no-op
//  shims so existing call sites (CrowdinLightSDK.stop(), etc.) still compile.
//

import Foundation

extension Bundle {
    /// Always false in the Pago fork — no global swizzle is ever installed.
    static var isSwizzled: Bool { false }

    /// No-op. Kept for source compatibility with CrowdinLightSDK.swizzle().
    class func swizzle() { }

    /// No-op. Kept for source compatibility with CrowdinLightSDK.unswizzle().
    class func unswizzle() { }

    /// Passthrough shim. With the global swizzle removed there is no longer a
    /// distinction between "original" and "swizzled" implementations; existing
    /// internal call sites (LocalizationProvider, LocalLocalizationExtractor)
    /// keep working by routing straight to the standard NSBundle method.
    @objc func swizzled_LocalizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        return self.localizedString(forKey: key, value: value, table: tableName)
    }
}
