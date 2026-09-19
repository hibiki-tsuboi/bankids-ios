# OS互換性の確認

## 2026年9月19日の確認結果

- Xcode 27.0（27A266a）・iOS 27.0 SDKで実機向けReleaseビルドに成功。生成物の最低OSは26.0です。
- iOS 27.0（24A434）のiPhone 18 Proシミュレータで、Swift Testingの8項目（不正データ16パターンを含む）が成功しました。
- 同OSの専用シミュレータで、初回起動からの復元画面、入出金・振替・メモ編集・子供と口座の切り替え・再起動後の保持、保存先と復元ファイル選択画面の表示・キャンセルを確認するUIテスト3項目が成功しました。
- iOS 26.0のiPhone 17 Pro専用シミュレータでも、同じiOS 27 SDKビルドを使用し、データ処理8項目とUIテスト3項目がすべて成功しました。
- iOS 27の標準保存画面には「キャンセル」ボタンが表示されないため、UIテストはシートを下へスワイプして閉じる操作にも対応しています。
- iPhone実機、iPad、AirDrop、iCloud Drive、実際のOSアップデート前後でのデータ保持は未検証です。

## ビルドとOS対応の違い

`IPHONEOS_DEPLOYMENT_TARGET = 26.0`は対応する最低OSです。iOS 27で動かすために27.0へ上げる必要はありません。SDKはビルドに使うAPI・ツールのバージョン、実行先は実際にテストするOSです。両方を確認してください。

以前のSDKでビルドしたアプリも、新しいOSで動く場合があります。ビルド成功だけで動作確認済みとはせず、起動、画面操作、保存済みデータの読み込みを実際のOS上で確認します。公開済みアプリと、このリポジトリから新しくビルドしたアプリの検証結果は区別してください。

## シミュレータでの確認

Xcode 27とiOS 27シミュレータランタイムを使用します。ほかの開発作業と端末を共有せず、実行先のIDを指定すると干渉を避けられます。

```bash
xcodebuild -version
xcodebuild -showsdks
xcodebuild -project Bankids.xcodeproj -scheme Bankids -showdestinations

# 表示されたiOS 27端末のIDを指定する
xcodebuild -project Bankids.xcodeproj -scheme Bankids \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' \
  -derivedDataPath build/DerivedData -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO test

# 実機向けRelease構成をビルド（署名・配布は行わない）
xcodebuild -project Bankids.xcodeproj -scheme Bankids \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath build/ReleaseVerification CODE_SIGNING_ALLOWED=NO build
```

最低対応OSのiOS 26.0でも同じテストを実行します。XcodeのTestレポートで失敗箇所と添付スクリーンショットを確認できます。

UIテストは、テストごとのUUIDを`BANKIDS_UI_TEST_ID`に渡し、専用のSwiftDataストアとUserDefaultsを使用します。同じテスト内の再起動ではその保存先を再利用します。この切り替えはDebugビルドにのみ含まれます。

## 実機・公開前の確認

1. 現在のデータをバックアップしてから、iOS 27の実機で既存アプリの起動と残高・履歴を確認する。
2. 新しいReleaseビルドをTestFlightなどで上書きインストールし、既存データと選択中の口座が残っていることを確認する。
3. 入金・出金・残高不足・振替・メモ編集・子供の切り替えを行い、アプリ再起動後も結果が残ることを確認する。
4. バックアップを「ファイル」に保存し、AirDropやiCloud Driveで別の端末へ渡す。復元前の内容確認、キャンセル、復元後の残高と履歴を確認する。
5. 対応するiPadと、文字サイズを大きくした状態でも、入力欄と確認ボタンが操作できることを確認する。

シミュレータの成功だけで、実機のAirDrop・iCloud Drive・App Store公開済みバイナリ・OSアップデートによる既存ストアの引き継ぎまで確認できたことにはなりません。

参考: [AppleのReleaseビルド検証ガイド](https://developer.apple.com/documentation/xcode/testing-a-release-build)、[iOS 27リリースノート](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes)。
