import Foundation

enum IPAError: LocalizedError, Equatable {
    case unreadableArchive
    case missingInfoPlist
    case invalidInfoPlist
    case missingEntry(String)
    case invalidBundleIdentifier
    case exportFailed(String)
    case validationFailed([String])

    var errorDescription: String? {
        switch self {
        case .unreadableArchive:
            return "此文件不是有效的 IPA 或 ZIP 归档。"
        case .missingInfoPlist:
            return "找不到 Payload/App.app/Info.plist。"
        case .invalidInfoPlist:
            return "无法读取 Info.plist。"
        case let .missingEntry(path):
            return "归档中缺少 \(path)。"
        case .invalidBundleIdentifier:
            return "应用没有有效的 Bundle ID。"
        case let .exportFailed(message):
            return message
        case let .validationFailed(problems):
            return problems.joined(separator: "\n")
        }
    }
}

struct SimpleError: LocalizedError {

    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}
