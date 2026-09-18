import PackagePlugin

@main
struct GenerateL10n: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let strings = context.package.directory
            .removingLastComponent()
            .appending(["podcasts", "en.lproj", "Localizable.strings"])
        return [
            .prebuildCommand(
                displayName: "Generate L10n from \(strings.lastComponent)",
                executable: try context.tool(named: "swiftgen").path,
                arguments: [
                    "run", "strings", strings,
                    "--templateName", "structured-swift5",
                    "--param", "publicAccess",
                    "--param", "lookupFunction=localizedFormat",
                    "--output", context.pluginWorkDirectory.appending("Strings+Generated.swift")
                ],
                outputFilesDirectory: context.pluginWorkDirectory
            )
        ]
    }
}
