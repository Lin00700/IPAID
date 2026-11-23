import Foundation

struct IPAModifications: Equatable {
    var bundleIdentifier: String
    var displayName: String
    var marketingVersion: String
    var buildNumber: String
    var urlScheme: String
    var removedExtensions: Set<String> = []
    var icon: IPAIconReplacement?
    var plistOverrides = InfoPlistOverrides()
    var editedFiles: [String: Data] = [:]

    var trimmedBundleIdentifier: String {
        bundleIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedMarketingVersion: String {
        marketingVersion.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedBuildNumber: String {
        buildNumber.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedURLScheme: String {
        urlScheme.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var fingerprint: String {
        IPASettingsFingerprint.make(self)
    }

    func bundleIdentifierChanged(from info: IPABundleInfo) -> Bool {
        trimmedBundleIdentifier != info.bundleIdentifier
    }

    func displayNameChanged(from info: IPABundleInfo) -> Bool {
        trimmedDisplayName != info.displayName
    }

    func marketingVersionChanged(from info: IPABundleInfo) -> Bool {
        trimmedMarketingVersion != info.marketingVersion
    }

    func buildNumberChanged(from info: IPABundleInfo) -> Bool {
        trimmedBuildNumber != info.buildNumber
    }

    func urlSchemeChanged(from info: IPABundleInfo) -> Bool {
        trimmedURLScheme != info.urlScheme.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func hasChanges(from info: IPABundleInfo) -> Bool {
        bundleIdentifierChanged(from: info) ||
            displayNameChanged(from: info) ||
            marketingVersionChanged(from: info) ||
            buildNumberChanged(from: info) ||
            urlSchemeChanged(from: info) ||
            !removedExtensions.isEmpty ||
            icon != nil ||
            !plistOverrides.isEmpty ||
            !editedFiles.isEmpty
    }

    func problems(comparedTo info: IPABundleInfo) -> [String] {
        var problems: [String] = []

        if bundleIdentifierChanged(from: info) || trimmedBundleIdentifier.isEmpty {
            appendProblem(MetadataValidation.bundleIdentifier(trimmedBundleIdentifier), to: &problems)
        }

        if displayNameChanged(from: info) {
            appendProblem(MetadataValidation.displayName(trimmedDisplayName), to: &problems)
        }

        if marketingVersionChanged(from: info) {
            appendProblem(MetadataValidation.marketingVersion(trimmedMarketingVersion), to: &problems)
        }

        if buildNumberChanged(from: info) {
            appendProblem(MetadataValidation.buildNumber(trimmedBuildNumber), to: &problems)
        }

        if urlSchemeChanged(from: info) || !info.urlScheme.isEmpty {
            appendProblem(
                MetadataValidation.urlScheme(
                    trimmedURLScheme,
                    allowEmpty: info.urlScheme.isEmpty
                ),
                to: &problems
            )
        }

        for root in removedExtensions.sorted() where !info.extensions.contains(where: { $0.root == root }) {
            problems.append("未知的应用扩展。")
        }

        for key in plistOverrides.values.keys.sorted() where ProtectedPlistKeys.isProtected(key) {
            problems.append("\(key) 由 IPAID 管理，无法覆盖。")
        }

        for key in plistOverrides.removedKeys.sorted() where ProtectedPlistKeys.isProtected(key) {
            problems.append("\(key) 为必需项，无法删除。")
        }

        if let icon {
            problems.append(contentsOf: icon.validate(against: info.iconPlan))
        }

        var seen = Set<String>()
        return problems.filter { seen.insert($0).inserted }
    }

    private func appendProblem(_ message: String, to problems: inout [String]) {
        if !message.isEmpty {
            problems.append(message)
        }
    }
}

struct IPAModificationChange: Identifiable, Equatable {
    let id: String
    let label: String
    let original: String
    let updated: String
}

struct IPAModificationSummary: Equatable {
    var changes: [IPAModificationChange]
    var removedFiles: [String]
    var addedFiles: [String]
    var modifiedFiles: [String]
    var iconFilePaths: [String]
    var warnings: [String]

    var isEmpty: Bool {
        changes.isEmpty && removedFiles.isEmpty && addedFiles.isEmpty && modifiedFiles.isEmpty
    }

    init(
        info: IPABundleInfo,
        entries: [IPAEntry],
        modifications: IPAModifications
    ) {
        var changes: [IPAModificationChange] = []
        var modifiedFiles: [String] = []
        var warnings: [String] = []

        if modifications.bundleIdentifierChanged(from: info) {
            changes.append(
                IPAModificationChange(
                    id: "bundleIdentifier",
                    label: "Bundle ID",
                    original: info.bundleIdentifier,
                    updated: modifications.trimmedBundleIdentifier
                )
            )
        }

        if modifications.displayNameChanged(from: info) {
            changes.append(
                IPAModificationChange(
                    id: "displayName",
                    label: "显示名称",
                    original: info.displayName,
                    updated: modifications.trimmedDisplayName
                )
            )
        }

        if modifications.marketingVersionChanged(from: info) {
            changes.append(
                IPAModificationChange(
                    id: "marketingVersion",
                    label: "版本号",
                    original: info.marketingVersion.isEmpty ? "无" : info.marketingVersion,
                    updated: modifications.trimmedMarketingVersion
                )
            )
            warnings.append("应用内的版本显示不会随之改变。")
        }

        if modifications.buildNumberChanged(from: info) {
            changes.append(
                IPAModificationChange(
                    id: "buildNumber",
                    label: "构建号",
                    original: info.buildNumber.isEmpty ? "无" : info.buildNumber,
                    updated: modifications.trimmedBuildNumber
                )
            )
        }

        if modifications.urlSchemeChanged(from: info) {
            changes.append(
                IPAModificationChange(
                    id: "urlScheme",
                    label: "URL Scheme",
                    original: info.urlScheme.isEmpty ? "无" : info.urlScheme,
                    updated: modifications.trimmedURLScheme.isEmpty ? "无" : modifications.trimmedURLScheme
                )
            )
        }

        if !modifications.removedExtensions.isEmpty {
            changes.append(
                IPAModificationChange(
                    id: "extensions",
                    label: "扩展",
                    original: "\(info.extensions.count)",
                    updated: "\(info.extensions.count - modifications.removedExtensions.count)"
                )
            )
        }

        if let icon = modifications.icon {
            changes.append(
                IPAModificationChange(
                    id: "icon",
                    label: "图标",
                    original: info.iconPlan.existingSlots.isEmpty ? "内置图标" : "原图标",
                    updated: "\(icon.imageName)（\(icon.files.count) 个文件）"
                )
            )

            if info.iconPlan.usesAssetCatalog {
                warnings.append("Assets.car 内的图标无法替换，IPAID 会改为添加独立的图标文件。")
            }
        }

        if !modifications.plistOverrides.isEmpty {
            changes.append(
                IPAModificationChange(
                    id: "advanced",
                    label: "Info.plist",
                    original: "应用设置",
                    updated: "\(modifications.plistOverrides.changeCount) 处修改"
                )
            )
        }

        if !modifications.editedFiles.isEmpty {
            let count = modifications.editedFiles.count

            changes.append(
                IPAModificationChange(
                    id: "editedFiles",
                    label: "已编辑文件",
                    original: count == 1 ? "1 个文件" : "\(count) 个文件",
                    updated: "已保存"
                )
            )
        }

        let removedFiles = entries
            .filter { entry in
                modifications.removedExtensions.contains { root in
                    entry.path.hasPrefix(root)
                }
            }
            .map(\.path)

        let addedFiles = modifications.icon == nil
            ? [String]()
            : info.iconPlan.slots.filter { !$0.isExisting }.map(\.path)

        if modifications.bundleIdentifierChanged(from: info) ||
            modifications.displayNameChanged(from: info) ||
            modifications.marketingVersionChanged(from: info) ||
            modifications.buildNumberChanged(from: info) ||
            modifications.urlSchemeChanged(from: info) ||
            !modifications.plistOverrides.isEmpty ||
            modifications.icon != nil {
            modifiedFiles.append(info.infoPlistPath)
        }

        if modifications.bundleIdentifierChanged(from: info) {
            for item in info.extensions where !modifications.removedExtensions.contains(item.root) {
                modifiedFiles.append(item.infoPlistPath)
            }
        }

        if let icon = modifications.icon {
            for slot in info.iconPlan.existingSlots where icon.files[slot.path] != nil {
                modifiedFiles.append(slot.path)
            }
        }

        for path in modifications.editedFiles.keys where !modifications.removedExtensions.contains(where: { path.hasPrefix($0) }) {
            modifiedFiles.append(path)
        }

        self.changes = changes
        self.removedFiles = removedFiles
        self.addedFiles = addedFiles
        self.modifiedFiles = Array(Set(modifiedFiles)).sorted()
        self.iconFilePaths = Array(
            Set(addedFiles + modifiedFiles)
                .intersection(Set(info.iconPlan.slots.map(\.path)))
        ).sorted()
        self.warnings = warnings
    }
}
