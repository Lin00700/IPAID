import Foundation

enum MetadataValidation {

    static let cannotBeEmpty = "不能为空"

    static func bundleIdentifier(_ id: String) -> String {
        let clean = id.trimmingCharacters(in: .whitespacesAndNewlines)

        if clean.isEmpty {
            return "Bundle ID 不能为空。"
        }

        if clean.count > 120 {
            return "Bundle ID 太长。"
        }

        if !clean.contains(".") {
            return "Bundle ID 至少要包含一个点号。"
        }

        if clean.contains("..") {
            return "Bundle ID 不能包含连续的两个点号。"
        }

        let allowed = CharacterSet(
            charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-"
        )

        if clean.rangeOfCharacter(from: allowed.inverted) != nil {
            return "Bundle ID 含有无效字符。"
        }

        if clean.hasPrefix(".") || clean.hasSuffix(".") {
            return "Bundle ID 不能以点号开头或结尾。"
        }

        return ""
    }

    static func displayName(_ name: String) -> String {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if clean.isEmpty {
            return "显示名称不能为空。"
        }

        if clean.count > 30 {
            return "显示名称太长。"
        }

        return ""
    }

    static func urlScheme(_ scheme: String, allowEmpty: Bool) -> String {
        let clean = scheme.trimmingCharacters(in: .whitespacesAndNewlines)

        if clean.isEmpty {
            return allowEmpty ? "" : "URL Scheme 不能为空。"
        }

        if clean.count > 100 {
            return "URL Scheme 太长。"
        }

        if clean.contains("://") || clean.contains("/") || clean.contains(" ") {
            return "URL Scheme 含有无效字符。"
        }

        let allowed = CharacterSet(
            charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+.-"
        )

        if clean.rangeOfCharacter(from: allowed.inverted) != nil {
            return "URL Scheme 含有无效字符。"
        }

        guard let first = clean.first, first.isLetter else {
            return "URL Scheme 必须以字母开头。"
        }

        return ""
    }

    static func marketingVersion(_ version: String) -> String {
        let clean = version.trimmingCharacters(in: .whitespacesAndNewlines)

        if clean.isEmpty {
            return "版本号不能为空。"
        }

        if clean.count > 18 {
            return "版本号太长。"
        }

        let parts = clean.split(separator: ".", omittingEmptySubsequences: false)

        if parts.isEmpty || parts.count > 3 {
            return "版本号最多三段数字，用点号分隔。"
        }

        for part in parts {
            if part.isEmpty || part.count > 9 || part.contains(where: { !$0.isNumber }) {
                return "版本号只能由数字和点号组成。"
            }
        }

        return ""
    }

    static func buildNumber(_ build: String) -> String {
        let clean = build.trimmingCharacters(in: .whitespacesAndNewlines)

        if clean.isEmpty {
            return "构建号不能为空。"
        }

        if clean.count > 18 {
            return "构建号太长。"
        }

        let parts = clean.split(separator: ".", omittingEmptySubsequences: false)

        if parts.count > 3 {
            return "构建号最多三段数字，用点号分隔。"
        }

        for part in parts {
            if part.isEmpty || part.count > 9 || part.contains(where: { !$0.isNumber }) {
                return "构建号只能包含数字和点号。"
            }
        }

        return ""
    }
}
