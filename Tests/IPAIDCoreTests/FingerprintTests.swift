import XCTest
@testable import IPAIDCore

final class FingerprintTests: XCTestCase {

    private func baseModifications() -> IPAModifications {
        IPAModifications(
            bundleIdentifier: "com.example.app",
            displayName: "Example",
            marketingVersion: "1.2",
            buildNumber: "42",
            urlScheme: "example"
        )
    }

    func testIconFingerprintUsesContentNotByteCount() {
        let first = Fixtures.pngData(width: 60, height: 60)
        var second = first
        second[40] = first[40] ^ 0xFF

        XCTAssertEqual(first.count, second.count)

        let path = "Payload/Example.app/AppIcon60x60@2x.png"

        var modifications = baseModifications()
        modifications.icon = IPAIconReplacement(
            imageName: "icon.png",
            previewData: Data(),
            files: [path: first]
        )
        let original = modifications.fingerprint

        modifications.icon = IPAIconReplacement(
            imageName: "icon.png",
            previewData: Data(),
            files: [path: second]
        )

        XCTAssertNotEqual(original, modifications.fingerprint)
    }

    func testIconFingerprintIgnoresFileOrder() {
        let a = Fixtures.pngData(width: 60, height: 60)
        let b = Fixtures.pngData(width: 120, height: 120)

        var first = baseModifications()
        first.icon = IPAIconReplacement(
            imageName: "icon.png",
            previewData: Data(),
            files: [
                "Payload/Example.app/AppIcon60x60@2x.png": a,
                "Payload/Example.app/AppIcon60x60@3x.png": b
            ]
        )

        var second = baseModifications()
        second.icon = IPAIconReplacement(
            imageName: "icon.png",
            previewData: Data(),
            files: [
                "Payload/Example.app/AppIcon60x60@3x.png": b,
                "Payload/Example.app/AppIcon60x60@2x.png": a
            ]
        )

        XCTAssertEqual(first.fingerprint, second.fingerprint)
    }

    func testPlistOverrideTypesProduceDifferentFingerprints() {
        var modifications = baseModifications()
        modifications.plistOverrides.set(.integer(1), for: "CustomKey")
        let integer = modifications.fingerprint

        modifications.plistOverrides.set(.string("1"), for: "CustomKey")
        let text = modifications.fingerprint
        XCTAssertNotEqual(integer, text)

        modifications.plistOverrides.set(.bool(true), for: "CustomKey")
        let flag = modifications.fingerprint
        XCTAssertNotEqual(text, flag)

        modifications.plistOverrides.set(.string("Yes"), for: "CustomKey")
        XCTAssertNotEqual(flag, modifications.fingerprint)
    }

    func testRemovedKeysChangeFingerprint() {
        var modifications = baseModifications()
        let plain = modifications.fingerprint

        modifications.plistOverrides.remove("MinimumOSVersion")
        XCTAssertNotEqual(plain, modifications.fingerprint)

        modifications.plistOverrides.reset("MinimumOSVersion")
        XCTAssertEqual(plain, modifications.fingerprint)
    }

    func testExtensionRemovalChangesFingerprint() {
        var modifications = baseModifications()
        let plain = modifications.fingerprint

        modifications.removedExtensions = ["Payload/Example.app/PlugIns/Widget.appex/"]
        XCTAssertNotEqual(plain, modifications.fingerprint)
    }

    func testFingerprintTracksEditedFiles() {
        let plain = baseModifications()

        var edited = plain
        edited.editedFiles["Payload/Example.app/config.txt"] = Data("a".utf8)

        XCTAssertNotEqual(plain.fingerprint, edited.fingerprint)

        var changed = edited
        changed.editedFiles["Payload/Example.app/config.txt"] = Data("b".utf8)

        XCTAssertNotEqual(edited.fingerprint, changed.fingerprint)
    }

    func testFingerprintIsStableAcrossInstances() {
        let first = baseModifications().fingerprint
        let second = baseModifications().fingerprint

        XCTAssertEqual(first, second)
    }

    func testVersionReferenceMatchingIgnoresLongerNumbers() {
        XCTAssertTrue(IPAVersionReferenceScanner.containsVersion("1.2", in: "Version 1.2"))
        XCTAssertTrue(IPAVersionReferenceScanner.containsVersion("1.2", in: "1.2"))
        XCTAssertTrue(IPAVersionReferenceScanner.containsVersion("1.2", in: "app-1.2-beta"))
        XCTAssertFalse(IPAVersionReferenceScanner.containsVersion("1.2", in: "Version 1.2.3"))
        XCTAssertFalse(IPAVersionReferenceScanner.containsVersion("1.2", in: "Version 11.2"))
        XCTAssertFalse(IPAVersionReferenceScanner.containsVersion("1.2", in: "Version 1.20"))
        XCTAssertFalse(IPAVersionReferenceScanner.containsVersion("", in: "anything"))
        XCTAssertTrue(IPAVersionReferenceScanner.containsVersion("1.2", in: "1.2.3 also lists 1.2"))
    }

    func testExtensionDisplayNames() {
        XCTAssertEqual(
            IPAExtensionInfo.displayName(forRoot: "Payload/Example.app/PlugIns/Widget.appex/"),
            "Widget"
        )
        XCTAssertEqual(
            IPAExtensionInfo.displayName(
                forRoot: "Payload/Example.app/PlugIns/NotificationServiceExtension.appex/"
            ),
            "Notification Service"
        )
        XCTAssertEqual(
            IPAExtensionInfo.displayName(forRoot: "Payload/Example.app/PlugIns/ShareExtension.appex/"),
            "Share"
        )
        XCTAssertEqual(
            IPAExtensionInfo.displayName(forRoot: "Payload/Example.app/PlugIns/Widget.appex/"),
            IPAExtensionInfo(root: "Payload/Example.app/PlugIns/Widget.appex/", infoPlistPath: "", bundleIdentifier: "", displayName: "").name
        )
    }

    func testExtensionTipsMatchNames() {
        XCTAssertTrue(IPAExtensionInfo.tip(forName: "Widget").contains("小组件"))
        XCTAssertTrue(IPAExtensionInfo.tip(forName: "Safari").contains("Safari"))
        XCTAssertFalse(IPAExtensionInfo.tip(forName: "Something").isEmpty)
    }

    func testExtensionTipsPreferTheExtensionPoint() {
        let widget = IPAExtensionInfo.tip(
            forName: "Something",
            pointIdentifier: "com.apple.widgetkit-extension"
        )

        XCTAssertTrue(widget.contains("小组件"))

        let keyboard = IPAExtensionInfo.tip(
            forName: "Widget",
            pointIdentifier: "com.apple.keyboard-service"
        )

        XCTAssertTrue(keyboard.contains("键盘"))
        XCTAssertFalse(keyboard.contains("小组件"))
    }

    func testUnknownExtensionPointFallsBackToTheName() {
        let tip = IPAExtensionInfo.tip(
            forName: "Widget",
            pointIdentifier: "com.example.unknown-point"
        )

        XCTAssertTrue(tip.contains("小组件"))
    }

    func testUnknownExtensionFallsBackToTheGenericTip() {
        let tip = IPAExtensionInfo.tip(forName: "Mystery", pointIdentifier: "")

        XCTAssertEqual(
            tip,
            "应用扩展组件。移除后可减少签名与 App ID 占用，但应用的某些功能可能无法使用。"
        )
    }

    func testMiddleTruncation() {
        XCTAssertEqual(IPAFormatting.middleTruncated("short.ipa", limit: 34), "short.ipa")
        XCTAssertEqual(IPAFormatting.middleTruncated("abcdefghijklmnop", limit: 10), "abcd…mnop")
    }

    func testFileSizeFormatting() {
        XCTAssertEqual(IPAFormatting.fileSize(Int64(0)), "未知")
        XCTAssertFalse(IPAFormatting.fileSize(Int64(2048)).isEmpty)
    }
}
