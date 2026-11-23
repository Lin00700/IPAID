import Foundation

struct IPAExtensionInfo: Equatable, Identifiable {
    let root: String
    let infoPlistPath: String
    let bundleIdentifier: String
    let displayName: String
    var extensionPointIdentifier: String = ""

    var id: String {
        root
    }

    var name: String {
        Self.displayName(forRoot: root)
    }

    static func displayName(forRoot root: String) -> String {
        let folder = root
            .split(separator: "/")
            .last { $0.hasSuffix(".appex") }

        let raw: String

        if let folder {
            raw = String(folder).replacingOccurrences(of: ".appex", with: "")
        } else {
            raw = URL(fileURLWithPath: root)
                .deletingPathExtension()
                .lastPathComponent
        }

        return humanReadable(raw)
    }

    static func tip(forName name: String, pointIdentifier: String = "") -> String {
        if let point = tip(forPointIdentifier: pointIdentifier) {
            return point
        }

        let lower = name.lowercased()

        if lower.contains("widget") {
            return "提供桌面或锁定屏幕小组件支持。移除后该小组件将无法使用。"
        }

        if lower.contains("intent") || lower.contains("siri") {
            return "处理 Siri、快捷指令或 App Intent 操作。移除后相关自动化功能可能失效。"
        }

        if lower.contains("notification service") {
            return "处理通知的增强内容、图片或媒体。移除后通知可能只显示基础样式。"
        }

        if lower.contains("notification content") {
            return "提供自定义通知布局。移除后可能无法显示富通知界面。"
        }

        if lower.contains("notification") {
            return "支持与通知相关的功能。移除后可能影响提醒或通知预览。"
        }

        if lower.contains("safari") {
            return "提供 Safari 集成。移除后 Safari 扩展功能可能失效。"
        }

        if lower.contains("share") {
            return "提供分享面板集成。移除后应用可能不再出现在分享菜单中。"
        }

        if lower.contains("watch") {
            return "提供 Apple Watch 支持。移除后 watchOS 配套功能可能失效。"
        }

        return "应用扩展组件。移除后可减少签名与 App ID 占用，但应用的某些功能可能无法使用。"
    }

    static func tip(forPointIdentifier identifier: String) -> String? {
        switch identifier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "com.apple.widgetkit-extension":
            return "提供桌面、锁定屏幕或待机显示小组件。移除后此应用的小组件将无法使用。"

        case "com.apple.widget-extension":
            return "提供旧版今日小组件，在桌面右滑时显示。"

        case "com.apple.notification-service-extension":
            return "为通知附加图片和媒体。移除后通知会变得简单。"

        case "com.apple.notification-content-extension":
            return "绘制自定义通知布局。移除后可能无法显示富通知界面。"

        case "com.apple.share-services":
            return "把此应用加入系统分享面板。移除后应用将不再出现在分享菜单中。"

        case "com.apple.safari.extension", "com.apple.safari.content-blocker":
            return "提供 Safari 扩展或内容拦截器。移除后 Safari 中的该功能将关闭。"

        case "com.apple.intents-service", "com.apple.intents-ui-service":
            return "处理 Siri、快捷指令和 App Intent。移除后这些操作可能失效。"

        case "com.apple.keyboard-service":
            return "提供自定义键盘。移除后该键盘会从系统设置中消失。"

        case "com.apple.watchkit-extension":
            return "提供 watchOS 应用。移除后 Apple Watch 相关功能可能失效。"

        case "com.apple.background-asset-downloader-extension":
            return "在后台下载 App Store 资源。移除后首次启动可能变慢。"

        case "com.apple.fileprovider-nonui":
            return "向「文件」App 提供内容。移除后「文件」中将不再显示此应用的位置。"

        case "com.apple.callkit.call-directory":
            return "向「电话」提供来电识别。移除后此应用无法识别来电。"

        case "com.apple.photo-editing":
            return "为「照片」提供编辑工具。移除后照片编辑器中不再有这些工具。"

        case "com.apple.action-extension":
            return "向分享面板和服务菜单添加操作。移除后这些操作会消失。"

        case "com.apple.authentication-services-credential-provider-ui":
            return "向自动填充提供已保存的密码。移除后此应用无法在其他地方填充密码。"

        default:
            return nil
        }
    }

    static func humanReadable(_ raw: String) -> String {
        var name = raw

        if name.hasSuffix("Extension") {
            name.removeLast("Extension".count)
        }

        name = name
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        var result = ""
        var previousWasLowercaseOrNumber = false

        for character in name {
            let scalar = String(character)
            let isUppercase = scalar.rangeOfCharacter(from: .uppercaseLetters) != nil
            let isNumber = scalar.rangeOfCharacter(from: .decimalDigits) != nil

            if isUppercase && previousWasLowercaseOrNumber && !result.hasSuffix(" ") {
                result.append(" ")
            }

            result.append(character)

            previousWasLowercaseOrNumber =
                scalar.rangeOfCharacter(from: .lowercaseLetters) != nil || isNumber
        }

        let cleaned = result
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? raw : cleaned
    }
}

struct IPABundleInfo: Equatable {
    let appRoot: String
    let infoPlistPath: String
    let bundleIdentifier: String
    let displayName: String
    let bundleName: String
    let marketingVersion: String
    let buildNumber: String
    let minimumOSVersion: String
    let executable: String
    let urlScheme: String
    let extensions: [IPAExtensionInfo]
    let iconPlan: IPAIconPlan
    let architectures: [String]
    let fileSize: Int64
    var targetSDK: String = ""
    var deviceFamilies: [String] = []

    var executablePath: String {
        executable.isEmpty ? appRoot : appRoot + executable
    }

    var deviceFamilyLabel: String {
        deviceFamilies.isEmpty ? "" : deviceFamilies.joined(separator: ", ")
    }
}

enum IPABundleParsing {

    static func deviceFamilies(from dictionary: [String: Any]) -> [String] {
        guard let families = dictionary["UIDeviceFamily"] as? [Any] else {
            return []
        }

        var result: [String] = []

        for item in families {
            guard let number = item as? Int else { continue }

            let name: String

            switch number {
            case 1: name = "iPhone"
            case 2: name = "iPad"
            case 3: name = "Apple TV"
            case 4: name = "Apple Watch"
            case 6: name = "Mac"
            case 7: name = "Vision"
            default: name = "设备族 \(number)"
            }

            if !result.contains(name) {
                result.append(name)
            }
        }

        return result
    }

    static func targetSDK(from dictionary: [String: Any]) -> String {
        for key in ["DTSDKName", "DTPlatformVersion", "DTSDKBuild"] {
            if let value = dictionary[key] as? String, !value.isEmpty {
                return value
            }
        }

        return ""
    }

    static func displayName(from dictionary: [String: Any], appRoot: String) -> String {
        if let name = dictionary["CFBundleDisplayName"] as? String, !name.isEmpty {
            return name
        }

        if let name = dictionary["CFBundleName"] as? String, !name.isEmpty {
            return name
        }

        let folder = appRoot.split(separator: "/").dropLast().last.map(String.init) ?? ""
        return folder.replacingOccurrences(of: ".app", with: "")
    }

    static func firstURLScheme(from dictionary: [String: Any]) -> String {
        guard let types = dictionary["CFBundleURLTypes"] as? [[String: Any]] else {
            return ""
        }

        for type in types {
            if let schemes = type["CFBundleURLSchemes"] as? [String],
               let first = schemes.first {
                return first
            }
        }

        return ""
    }

    static func updateURLScheme(
        in dictionary: inout [String: Any],
        scheme: String,
        bundleIdentifier: String
    ) {
        if var types = dictionary["CFBundleURLTypes"] as? [[String: Any]], !types.isEmpty {
            if var schemes = types[0]["CFBundleURLSchemes"] as? [String], !schemes.isEmpty {
                schemes[0] = scheme
                types[0]["CFBundleURLSchemes"] = schemes
            } else {
                types[0]["CFBundleURLSchemes"] = [scheme]
            }
            dictionary["CFBundleURLTypes"] = types
        } else {
            dictionary["CFBundleURLTypes"] = [[
                "CFBundleURLName": bundleIdentifier,
                "CFBundleURLSchemes": [scheme]
            ]]
        }
    }
}
