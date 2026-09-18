import PackagePlugin

@main
struct GenerateL10n: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        let strings = context.package.directory
            .removingLastComponent()
            .appending(["podcasts", "en.lproj", "Localizable.strings"])
        let outputDirectory = context.pluginWorkDirectory.appending("Generated")
        let stamp = context.pluginWorkDirectory.appending("L10n.stamp")
        let swiftgen = [
            try context.tool(named: "swiftgen").path.string,
            "run", "strings", strings.string,
            "--templateName", "structured-swift5",
            "--param", "publicAccess",
            "--param", "lookupFunction=localizedFormat",
            "--output", outputDirectory.appending("Strings+Generated.swift").string
        ]
        return [
            .prebuildCommand(
                displayName: "Generate L10n from \(strings.lastComponent)",
                executable: Path("/bin/sh"),
                arguments: [
                    "-c",
                    """
                    stamp="$1" strings="$2" outputs="$3"; shift 3
                    [ "$stamp" -nt "$strings" ] && [ "$(cat "$stamp")" = "$*" ] && exit 0
                    mkdir -p "$outputs" && "$@" && printf '%s' "$*" > "$stamp"
                    """,
                    "sh", stamp.string, strings.string, outputDirectory.string
                ] + swiftgen,
                outputFilesDirectory: outputDirectory
            )
        ]
    }
}
