//
//  AccountManager.swift
//  Bankids
//
//  Created by Hibiki Tsuboi on 2026/02/09.
//

import Foundation

@Observable
final class AccountManager {
    private static let selectedAccountIDKey = "selectedAccountID"
    private static let selectedWalletIDKey = "selectedWalletID"
    private let defaults: UserDefaults

    // Recreate screens holding model references after a complete restore.
    var dataRevision = UUID()

    var selectedAccountID: UUID? {
        didSet {
            if let id = selectedAccountID {
                defaults.set(id.uuidString, forKey: Self.selectedAccountIDKey)
            } else {
                defaults.removeObject(forKey: Self.selectedAccountIDKey)
            }
            // アカウント切替時にウォレット選択をリセット
            if oldValue != selectedAccountID {
                selectedWalletID = nil
            }
        }
    }

    var selectedWalletID: UUID? {
        didSet {
            if let id = selectedWalletID {
                defaults.set(id.uuidString, forKey: Self.selectedWalletIDKey)
            } else {
                defaults.removeObject(forKey: Self.selectedWalletIDKey)
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Account selection can clear the stored wallet through its observer.
        // Read both values before assigning either observable property.
        let savedAccountID = defaults.string(forKey: Self.selectedAccountIDKey)
        let savedWalletID = defaults.string(forKey: Self.selectedWalletIDKey)
        if let string = savedAccountID,
           let uuid = UUID(uuidString: string) {
            self.selectedAccountID = uuid
        }
        if let string = savedWalletID,
           let uuid = UUID(uuidString: string) {
            self.selectedWalletID = uuid
        }
    }
}
