import SwiftSyntax
import SwiftSyntaxMacros
import SwiftCompilerPlugin

/// Property info extracted from the class/struct declaration
struct PropertyInfo {
    let name: String
    let type: String
    let isOptional: Bool
    let isDate: Bool
    let defaultValue: String?
    /// Custom column name from @GRDBColumn attribute, if specified
    let columnName: String?

    /// The name to use for the database column (columnName if specified, otherwise name)
    var databaseColumnName: String {
        columnName ?? name
    }
}

public struct GRDBRecordMacro: MemberMacro, ExtensionMacro {

    // MARK: - ExtensionMacro

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        if isNSObjectSubclass(declaration) {
            // For NSObject subclasses: add full GRDB conformances
            let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed): FetchableRecord, TableRecord, Decodable {}")
            return [extensionDecl]
        } else {
            // For Codable structs/classes: add Codable, FetchableRecord, PersistableRecord, TableRecord conformances
            // TableRecord is required by PersistableRecord
            // This is harmless if already declared, as Swift allows redundant conformance declarations
            let extensionDecl = try ExtensionDeclSyntax("extension \(type.trimmed): Codable, FetchableRecord, PersistableRecord, TableRecord {}")
            return [extensionDecl]
        }
    }

    // MARK: - MemberMacro

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract table name from macro argument (optional)
        let tableName = extractTableName(from: node)

        let isNSObject = isNSObjectSubclass(declaration)

        // Determine access level from the type declaration
        let isPublic = declaration.modifiers.contains { modifier in
            modifier.name.tokenKind == .keyword(.public)
        }
        let accessModifier = isPublic ? "public " : ""

        // Generate the members
        var members: [DeclSyntax] = []

        // 1. Generate databaseTableName if table parameter provided
        if let tableName = tableName {
            members.append("""
                \(raw: accessModifier)static let databaseTableName = "\(raw: tableName)"
                """)
        }

        if isNSObject {
            // For NSObject subclasses: generate CodingKeys, init(from decoder:), and Columns
            let properties = extractObjcProperties(from: declaration)

            // 2. Generate CodingKeys enum
            members.append(generateCodingKeys(properties: properties))

            // 3. Generate init(from decoder:)
            members.append(generateDecodableInit(properties: properties, accessModifier: accessModifier))

            // 4. Generate Columns enum
            members.append(generateColumns(properties: properties, accessModifier: accessModifier))
        } else {
            // For Codable structs/classes: generate CodingKeys and Columns
            let properties = extractAllStoredProperties(from: declaration)

            // 2. Generate CodingKeys enum (needed for custom column names)
            members.append(generateCodingKeys(properties: properties))

            // 3. Generate Columns enum referencing CodingKeys
            members.append(generateColumns(properties: properties, accessModifier: accessModifier))
        }

        return members
    }

    // MARK: - NSObject Detection

    /// Check if the declaration inherits from NSObject
    private static func isNSObjectSubclass(_ declaration: some DeclGroupSyntax) -> Bool {
        guard let classDecl = declaration.as(ClassDeclSyntax.self),
              let inheritanceClause = classDecl.inheritanceClause else {
            return false
        }

        // Check inheritance list for NSObject
        for inheritedType in inheritanceClause.inheritedTypes {
            let typeName = inheritedType.type.trimmedDescription
            if typeName == "NSObject" {
                return true
            }
        }

        return false
    }

    // MARK: - Helpers

    private static func extractTableName(from node: AttributeSyntax) -> String? {
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
              let firstArg = arguments.first,
              let stringLiteral = firstArg.expression.as(StringLiteralExprSyntax.self),
              let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) else {
            return nil
        }
        return segment.content.text
    }

    /// Check if a property has @GRDBIgnore attribute
    private static func hasGRDBIgnore(_ varDecl: VariableDeclSyntax) -> Bool {
        varDecl.attributes.contains { attr in
            if case .attribute(let attributeSyntax) = attr {
                return attributeSyntax.attributeName.trimmedDescription == "GRDBIgnore"
            }
            return false
        }
    }

    /// Extract properties with @objc attribute (for classes/NSObject subclasses)
    private static func extractObjcProperties(from declaration: some DeclGroupSyntax) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []

        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
                continue
            }

            // Skip properties marked with @GRDBIgnore
            guard !hasGRDBIgnore(varDecl) else { continue }

            // Only include properties with @objc attribute (database-stored properties)
            let hasObjc = varDecl.attributes.contains { attr in
                if case .attribute(let attributeSyntax) = attr {
                    return attributeSyntax.attributeName.trimmedDescription == "objc"
                }
                return false
            }
            guard hasObjc else { continue }

            if let propInfo = extractPropertyInfo(from: varDecl) {
                properties.append(propInfo)
            }
        }

        return properties
    }

    /// Extract all stored properties (for Codable structs)
    private static func extractAllProperties(from declaration: some DeclGroupSyntax) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []

        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindingSpecifier.tokenKind == .keyword(.var) else {
                continue
            }

            if let propInfo = extractPropertyInfo(from: varDecl) {
                properties.append(propInfo)
            }
        }

        return properties
    }

    /// Extract property info from a variable declaration
    private static func extractPropertyInfo(from varDecl: VariableDeclSyntax) -> PropertyInfo? {
        for binding in varDecl.bindings {
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                continue
            }

            let name = identifier.identifier.text

            // Skip computed properties (those with accessors but no initializer)
            if binding.accessorBlock != nil && binding.initializer == nil {
                continue
            }

            // Check for @GRDBColumn attribute
            let columnName = extractGRDBColumnName(from: varDecl)

            // Get type info
            var typeString = "Any"
            var isOptional = false
            var isDate = false

            if let typeAnnotation = binding.typeAnnotation {
                let type = typeAnnotation.type
                typeString = type.trimmedDescription

                if let optionalType = type.as(OptionalTypeSyntax.self) {
                    isOptional = true
                    let wrappedType = optionalType.wrappedType.trimmedDescription
                    isDate = wrappedType == "Date"
                    typeString = wrappedType
                } else {
                    isDate = typeString == "Date"
                }
            } else if let initializer = binding.initializer {
                // Infer type from initializer
                let initExpr = initializer.value.trimmedDescription
                if initExpr.contains("as Int64") || initExpr.contains(": Int64") {
                    typeString = "Int64"
                } else if initExpr.contains("as Int32") || initExpr.contains(": Int32") {
                    typeString = "Int32"
                } else if initExpr.contains("as Double") || initExpr.contains(": Double") {
                    typeString = "Double"
                } else if initExpr.contains("false") || initExpr.contains("true") {
                    typeString = "Bool"
                } else if initExpr.contains("\"") {
                    typeString = "String"
                } else if initExpr.contains(".") && !initExpr.contains("\"") {
                    // Numeric literal with decimal point like 1.0
                    typeString = "Double"
                }
            }

            // Get default value
            var defaultValue: String? = nil
            if let initializer = binding.initializer {
                let expr = initializer.value.trimmedDescription
                // Simplify the default value
                if expr.contains(" as ") {
                    // "0 as Int64" -> "0"
                    defaultValue = expr.components(separatedBy: " as ").first?.trimmingCharacters(in: .whitespaces)
                } else {
                    defaultValue = expr
                }
            }

            return PropertyInfo(
                name: name,
                type: typeString,
                isOptional: isOptional,
                isDate: isDate,
                defaultValue: defaultValue,
                columnName: columnName
            )
        }

        return nil
    }

    /// Extract the column name from @GRDBColumn attribute if present
    private static func extractGRDBColumnName(from varDecl: VariableDeclSyntax) -> String? {
        for attr in varDecl.attributes {
            guard case .attribute(let attributeSyntax) = attr,
                  attributeSyntax.attributeName.trimmedDescription == "GRDBColumn",
                  let arguments = attributeSyntax.arguments?.as(LabeledExprListSyntax.self),
                  let firstArg = arguments.first,
                  let stringLiteral = firstArg.expression.as(StringLiteralExprSyntax.self),
                  let segment = stringLiteral.segments.first?.as(StringSegmentSyntax.self) else {
                continue
            }
            return segment.content.text
        }
        return nil
    }

    private static func generateCodingKeys(properties: [PropertyInfo]) -> DeclSyntax {
        let cases = properties.map { prop -> String in
            if let columnName = prop.columnName {
                // Property has a custom column name
                return "case \(prop.name) = \"\(columnName)\""
            } else {
                return "case \(prop.name)"
            }
        }.joined(separator: "\n        ")

        return """
            enum CodingKeys: String, CodingKey {
                \(raw: cases)
            }
            """
    }

    private static func generateDecodableInit(properties: [PropertyInfo], accessModifier: String) -> DeclSyntax {
        var assignments: [String] = []

        for prop in properties {
            let decoder: String
            if prop.isOptional {
                decoder = "try container.decodeIfPresent(\(prop.type).self, forKey: .\(prop.name))"
            } else if let defaultValue = prop.defaultValue {
                decoder = "try container.decodeIfPresent(\(prop.type).self, forKey: .\(prop.name)) ?? \(defaultValue)"
            } else {
                decoder = "try container.decode(\(prop.type).self, forKey: .\(prop.name))"
            }
            assignments.append("\(prop.name) = \(decoder)")
        }

        let assignmentsCode = assignments.joined(separator: "\n        ")

        return """
            \(raw: accessModifier)required init(from decoder: Decoder) throws {
                super.init()
                let container = try decoder.container(keyedBy: CodingKeys.self)
                \(raw: assignmentsCode)
            }
            """
    }

    private static func generateColumns(properties: [PropertyInfo], accessModifier: String) -> DeclSyntax {
        let columns = properties.map { "\(accessModifier)static let \($0.name) = Column(CodingKeys.\($0.name))" }.joined(separator: "\n        ")

        return """
            \(raw: accessModifier)enum Columns {
                \(raw: columns)
            }
            """
    }

    /// Generate Columns enum for structs using string-based column names
    /// (since auto-synthesized CodingKeys are private)
    private static func generateColumnsForStruct(properties: [PropertyInfo]) -> DeclSyntax {
        let columns = properties.map { "static let \($0.name) = Column(\"\($0.databaseColumnName)\")" }.joined(separator: "\n        ")

        return """
            enum Columns {
                \(raw: columns)
            }
            """
    }

    /// Extract all stored properties from a declaration (for Codable types)
    private static func extractAllStoredProperties(from declaration: some DeclGroupSyntax) -> [PropertyInfo] {
        var properties: [PropertyInfo] = []

        for member in declaration.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindingSpecifier.tokenKind == .keyword(.var) ||
                  varDecl.bindingSpecifier.tokenKind == .keyword(.let) else {
                continue
            }

            // Skip static properties (they are not instance properties)
            let isStatic = varDecl.modifiers.contains { modifier in
                modifier.name.tokenKind == .keyword(.static)
            }
            guard !isStatic else { continue }

            // Skip properties marked with @GRDBIgnore
            guard !hasGRDBIgnore(varDecl) else { continue }

            for binding in varDecl.bindings {
                guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }

                // Skip computed properties (those with accessors but no initializer)
                if binding.accessorBlock != nil && binding.initializer == nil {
                    continue
                }

                let name = identifier.identifier.text

                // Check for @GRDBColumn attribute
                let columnName = extractGRDBColumnName(from: varDecl)

                properties.append(PropertyInfo(
                    name: name,
                    type: "Any", // Not needed for Columns generation
                    isOptional: false,
                    isDate: false,
                    defaultValue: nil,
                    columnName: columnName
                ))
            }
        }

        return properties
    }
}

/// Marker macro for custom column name mapping.
/// The actual work is done by @GRDBRecord which reads this attribute.
public struct GRDBColumnMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro doesn't generate any code - it's just a marker attribute
        // that @GRDBRecord reads to determine custom column names
        return []
    }
}

/// Marker macro to exclude a property from @GRDBRecord processing.
/// The actual work is done by @GRDBRecord which checks for this attribute.
public struct GRDBIgnoreMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro doesn't generate any code - it's just a marker attribute
        // that @GRDBRecord reads to determine which properties to skip
        return []
    }
}

@main
struct GRDBMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GRDBRecordMacro.self,
        GRDBColumnMacro.self,
        GRDBIgnoreMacro.self
    ]
}
