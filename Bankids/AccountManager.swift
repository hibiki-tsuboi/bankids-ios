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

    var selectedAccountID: UUID? {
        didSet {
            if let id = selectedAccountID {
                UserDefaults.standard.set(id.uuidString, forKey: Self.selectedAccountIDKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.selectedAccountIDKey)
            }
        }
    }

    init() {
        if let string = UserDefaults.standard.string(forKey: Self.selectedAccountIDKey),
           let uuid = UUID(uuidString: string) {
            self.selectedAccountID = uuid
        }
    }
}
