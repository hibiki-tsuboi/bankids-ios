import XCTest

final class CompatibilityTests: XCTestCase {
    @MainActor
    private func launchApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["BANKIDS_UI_TEST_ID"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        XCTAssertTrue(app.textFields["setup.name"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor
    func testFirstLaunchCanOpenRestoreWithoutCreatingAccount() {
        let app = launchApp()
        XCTAssertFalse(app.buttons["はじめる"].isEnabled)
        app.buttons["バックアップから復元"].tap()
        XCTAssertTrue(app.navigationBars["バックアップと復元"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["バックアップを書き出す"].isEnabled)
        XCTAssertTrue(app.buttons["バックアップを選ぶ"].isEnabled)
        attachScreenshot("初回起動からの復元画面", app: app)
        app.buttons["完了"].tap()
        XCTAssertTrue(app.textFields["setup.name"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testMoneyFlowsAndSelectionPersistAfterRelaunch() {
        let app = launchApp()
        createAccount(in: app)
        assertBalance("¥0", in: app)

        app.buttons["入金"].tap()
        enter("10000", in: app.textFields["0"])
        enter("Allowance", in: app.textFields["お年玉、お小遣いなど"])
        app.buttons["入金する"].tap()
        assertBalance("¥10,000", in: app)

        app.buttons["出金"].tap()
        enter("500", in: app.textFields["0"])
        app.buttons["出金する"].tap()
        assertBalance("¥9,500", in: app)

        app.buttons["出金"].tap()
        enter("99999", in: app.textFields["0"])
        app.buttons["出金する"].tap()
        XCTAssertTrue(app.alerts["残高不足"].waitForExistence(timeout: 5))
        app.alerts.buttons["OK"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        assertBalance("¥9,500", in: app)

        app.buttons["振替"].tap()
        enter("1000", in: app.textFields["0"])
        app.buttons["振替する"].tap()
        assertBalance("¥8,500", in: app)
        app.buttons["子供口座"].tap()
        assertBalance("¥1,000", in: app)

        app.staticTexts["親口座 → 子供口座"].tap()
        let memo = app.textFields["メモを入力"]
        XCTAssertTrue(memo.waitForExistence(timeout: 5))
        memo.tap()
        let current = memo.value as? String ?? ""
        memo.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + "Edited memo")
        app.buttons["保存"].tap()
        XCTAssertTrue(app.staticTexts["Edited memo"].waitForExistence(timeout: 5))

        app.buttons["すべての明細を見る"].tap()
        XCTAssertTrue(app.staticTexts["Edited memo"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()

        app.buttons["子供を選択"].tap()
        app.buttons["子供を追加"].tap()
        enter("Second", in: app.textFields["お子さまの名前"])
        app.buttons["追加"].tap()
        app.buttons["完了"].tap()
        assertBalance("¥0", in: app)
        app.buttons["子供を選択"].tap()
        app.buttons.containing(.staticText, identifier: "Compatibility").firstMatch.tap()
        assertBalance("¥8,500", in: app)
        app.buttons["子供口座"].tap()
        assertBalance("¥1,000", in: app)

        // Backgrounding gives SwiftData its normal autosave event before terminating.
        XCUIDevice.shared.press(.home)
        app.terminate()
        app.launch()
        assertBalance("¥1,000", in: app)
        XCTAssertTrue(app.staticTexts["Edited memo"].waitForExistence(timeout: 5))
        attachScreenshot("再起動後の残高と取引履歴", app: app)
    }

    @MainActor
    func testBackupFilePickersPresentAndDismiss() {
        let app = launchApp()
        createAccount(in: app)
        app.buttons["バックアップと復元"].tap()
        XCTAssertTrue(app.navigationBars["バックアップと復元"].waitForExistence(timeout: 5))
        app.buttons["バックアップを書き出す"].tap()
        let picker = app.navigationBars["FullDocumentManagerViewControllerNavigationBar"]
        XCTAssertTrue(picker.waitForExistence(timeout: 15), app.debugDescription)
        attachScreenshot("バックアップ保存先の選択", app: app)
        dismissFilePicker(in: app)
        XCTAssertTrue(app.buttons["バックアップを選ぶ"].waitForExistence(timeout: 5))
        app.buttons["バックアップを選ぶ"].tap()
        XCTAssertTrue(picker.waitForExistence(timeout: 15), app.debugDescription)
        attachScreenshot("復元ファイルの選択", app: app)
        dismissFilePicker(in: app)
        app.buttons["完了"].tap()
        assertBalance("¥0", in: app)
    }

    @MainActor
    private func dismissFilePicker(in app: XCUIApplication) {
        let picker = app.navigationBars["FullDocumentManagerViewControllerNavigationBar"]
        // The iOS 27 save sheet has no Cancel button; dismiss it using the system sheet gesture.
        let cancel = app.buttons["キャンセル"]
        if cancel.exists {
            cancel.tap()
        } else {
            picker.swipeDown()
        }
        XCTAssertTrue(picker.waitForNonExistence(timeout: 5), app.debugDescription)
    }

    @MainActor
    private func createAccount(in app: XCUIApplication) {
        enter("Compatibility", in: app.textFields["setup.name"])
        app.buttons["はじめる"].tap()
        XCTAssertTrue(app.staticTexts["home.balance"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func enter(_ text: String, in field: XCUIElement) {
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(text)
    }

    @MainActor
    private func assertBalance(_ expected: String, in app: XCUIApplication) {
        let balance = app.staticTexts["home.balance"]
        XCTAssertTrue(balance.waitForExistence(timeout: 10))
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: balance)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    @MainActor
    private func attachScreenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
