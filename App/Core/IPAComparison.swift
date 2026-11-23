import Foundation

struct IPAMetadataDifference: Identifiable, Equatable {
    let id: String
    let label: String
    let left: String
    let right: String

    var isDifferent: Bool {
        left != right
    }
}

struct IPAComparisonResult: Equatable {
    let leftName: String
    let rightName: String
    let metadata: [IPAMetadataDifference]
    let addedFiles: [String]
    let removedFiles: [String]
    let changedFiles: [String]
    let leftFileCount: Int
    let rightFileCount: Int

    var differingMetadata: [IPAMetadataDifference] {
        metadata.filter(\.isDifferent)
    }

    var hasDifferences: Bool {
        !differingMetadata.isEmpty ||
            !addedFiles.isEmpty ||
            !removedFiles.isEmpty ||
            !changedFiles.isEmpty
    }
}

enum IPAComparison {

    static func compare(
        left: IPAArchive,
        leftName: String,
        right: IPAArchive,
        rightName: String
    ) -> IPAComparisonResult {
        let leftInfo = left.info
        let rightInfo = right.info

        func value(_ text: String) -> String {
            text.isEmpty ? "无" : text
        }

        let metadata: [IPAMetadataDifference] = [
            IPAMetadataDifference(
                id: "name",
                label: "应用名称",
                left: value(leftInfo.displayName),
                right: value(rightInfo.displayName)
            ),
            IPAMetadataDifference(
                id: "bundleIdentifier",
                label: "Bundle ID",
                left: leftInfo.bundleIdentifier,
                right: rightInfo.bundleIdentifier
            ),
            IPAMetadataDifference(
                id: "marketingVersion",
                label: "版本号",
                left: value(leftInfo.marketingVersion),
                right: value(rightInfo.marketingVersion)
            ),
            IPAMetadataDifference(
                id: "buildNumber",
                label: "构建号",
                left: value(leftInfo.buildNumber),
                right: value(rightInfo.buildNumber)
            ),
            IPAMetadataDifference(
                id: "minimumOSVersion",
                label: "最低 iOS",
                left: value(leftInfo.minimumOSVersion),
                right: value(rightInfo.minimumOSVersion)
            ),
            IPAMetadataDifference(
                id: "executable",
                label: "可执行文件",
                left: value(leftInfo.executable),
                right: value(rightInfo.executable)
            ),
            IPAMetadataDifference(
                id: "architectures",
                label: "架构",
                left: value(leftInfo.architectures.joined(separator: ", ")),
                right: value(rightInfo.architectures.joined(separator: ", "))
            ),
            IPAMetadataDifference(
                id: "extensions",
                label: "扩展",
                left: "\(leftInfo.extensions.count)",
                right: "\(rightInfo.extensions.count)"
            ),
            IPAMetadataDifference(
                id: "extensionIDs",
                label: "扩展 ID",
                left: extensionIDs(leftInfo),
                right: extensionIDs(rightInfo)
            ),
            IPAMetadataDifference(
                id: "size",
                label: "文件大小",
                left: IPAFormatting.fileSize(leftInfo.fileSize),
                right: IPAFormatting.fileSize(rightInfo.fileSize)
            )
        ]

        let leftFiles = fileMap(left)
        let rightFiles = fileMap(right)

        let added = rightFiles.keys.filter { leftFiles[$0] == nil }.sorted()
        let removed = leftFiles.keys.filter { rightFiles[$0] == nil }.sorted()
        let changed = leftFiles.keys
            .filter { path in
                guard let right = rightFiles[path], let left = leftFiles[path] else {
                    return false
                }
                return left != right
            }
            .sorted()

        return IPAComparisonResult(
            leftName: leftName,
            rightName: rightName,
            metadata: metadata,
            addedFiles: added,
            removedFiles: removed,
            changedFiles: changed,
            leftFileCount: leftFiles.count,
            rightFileCount: rightFiles.count
        )
    }

    private static func extensionIDs(_ info: IPABundleInfo) -> String {
        let identifiers = info.extensions
            .map(\.bundleIdentifier)
            .filter { !$0.isEmpty }
            .sorted()

        return identifiers.isEmpty ? "无" : identifiers.joined(separator: ", ")
    }

    private struct FileFingerprint: Equatable {
        let checksum: UInt32
        let size: Int
        let compressedSize: Int
    }

    private static func fileMap(_ archive: IPAArchive) -> [String: FileFingerprint] {
        var result: [String: FileFingerprint] = [:]

        for entry in archive.entries where entry.kind != .directory {
            result[entry.path] = FileFingerprint(
                checksum: entry.checksum,
                size: entry.uncompressedSize,
                compressedSize: entry.compressedSize
            )
        }

        return result
    }
}
