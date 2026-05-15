//
//  PagoLocalizedBundle.swift
//  CrowdinSDK (Pago fork)
//
//  Routes localizedString lookups through Crowdin's in-memory localization
//  store before falling back to the bundle's own Localizable.strings resolution.
//
//  This replaces the previous process-wide method_exchangeImplementations on
//  NSBundle.localizedString(forKey:value:table:). Scoping interception to a
//  bundle subclass means host applications and any of their dependencies keep
//  their original NSLocalizedString behavior — only callers that explicitly
//  resolve their bundle as PagoLocalizedBundle receive Crowdin's translations.
//

import Foundation

@objc(PagoLocalizedBundle)
@objcMembers
public class PagoLocalizedBundle: Bundle, @unchecked Sendable {
    public override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let translation = Localization.current?.localizedString(for: key) {
            return translation
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}
