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

    var selectedAccountID: UUID? {
        didSet {
            if let id = selectedAccountID {
                UserDefaults.standard.set(id.uuidString, forKey: Self.selectedAccountIDKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.selectedAccountIDKey)
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
                UserDefaults.standard.set(id.uuidString, forKey: Self.selectedWalletIDKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.selectedWalletIDKey)
            }
        }
    }

    init() {
        if let string = UserDefaults.standard.string(forKey: Self.selectedAccountIDKey),
           let uuid = UUID(uuidString: string) {
            self.selectedAccountID = uuid
        }
        if let string = UserDefaults.standard.string(forKey: Self.selectedWalletIDKey),
           let uuid = UUID(uuidString: string) {
            self.selectedWalletID = uuid
        }
    }
}
