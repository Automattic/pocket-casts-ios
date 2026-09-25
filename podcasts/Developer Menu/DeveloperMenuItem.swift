import SwiftUI

struct DeveloperMenuSection {
    var title: String?
    var footer: String?
    let items: [DeveloperMenuItem]
}

struct DeveloperMenuItem: Identifiable {
    enum Kind {
        case action(@MainActor () -> Void)
        case destructive(@MainActor () -> Void)
        case toggle(get: @MainActor () -> Bool, set: @MainActor (Bool) -> Void)
        case sheet(@MainActor (_ dismiss: @escaping () -> Void) -> AnyView)
        case link(@MainActor () -> AnyView)
        case menu([DeveloperMenuSection])
        case value(String?)
        case custom(@MainActor () -> AnyView)
    }

    let title: String
    var subtitle: String?
    let kind: Kind

    var id: String { [title, subtitle].compactMap { $0 }.joined(separator: "\n") }

    static func action(_ title: String, subtitle: String? = nil, perform: @escaping @MainActor () -> Void) -> Self {
        Self(title: title, subtitle: subtitle, kind: .action(perform))
    }

    static func destructive(_ title: String, subtitle: String? = nil, perform: @escaping @MainActor () -> Void) -> Self {
        Self(title: title, subtitle: subtitle, kind: .destructive(perform))
    }

    static func toggle(_ title: String, subtitle: String? = nil, isOn get: @escaping @MainActor () -> Bool, set: @escaping @MainActor (Bool) -> Void) -> Self {
        Self(title: title, subtitle: subtitle, kind: .toggle(get: get, set: set))
    }

    static func sheet<Content: View>(_ title: String, subtitle: String? = nil, @ViewBuilder content: @escaping @MainActor (_ dismiss: @escaping () -> Void) -> Content) -> Self {
        Self(title: title, subtitle: subtitle, kind: .sheet { AnyView(content($0)) })
    }

    static func link<Destination: View>(_ title: String, subtitle: String? = nil, @ViewBuilder destination: @escaping @MainActor () -> Destination) -> Self {
        Self(title: title, subtitle: subtitle, kind: .link { AnyView(destination()) })
    }

    static func menu(_ title: String, subtitle: String? = nil, sections: [DeveloperMenuSection]) -> Self {
        Self(title: title, subtitle: subtitle, kind: .menu(sections))
    }

    static func menu(_ title: String, subtitle: String? = nil, items: [DeveloperMenuItem]) -> Self {
        menu(title, subtitle: subtitle, sections: [DeveloperMenuSection(items: items)])
    }

    static func value(_ title: String, _ value: String?) -> Self {
        Self(title: title, kind: .value(value))
    }

    static func custom<Content: View>(_ title: String, @ViewBuilder content: @escaping @MainActor () -> Content) -> Self {
        Self(title: title, kind: .custom { AnyView(content()) })
    }
}

struct DeveloperMenuSectionView: View {
    let section: DeveloperMenuSection

    var body: some View {
        Section {
            ForEach(section.items) { item in
                DeveloperMenuRow(item: item)
            }
        } header: {
            if let title = section.title {
                Text(title)
            }
        } footer: {
            if let footer = section.footer {
                Text(footer)
            }
        }
    }
}

struct DeveloperMenuRow: View {
    let item: DeveloperMenuItem

    @State private var presented: DeveloperMenuItem?
    @State private var confirming: DeveloperMenuItem?

    var body: some View {
        content
            .sheet(item: $presented) { item in
                if case .sheet(let content) = item.kind {
                    content { presented = nil }
                        .setupDefaultEnvironment()
                }
            }
            .confirmationDialog(confirming?.title ?? "", isPresented: isConfirming, titleVisibility: .visible, presenting: confirming) { item in
                Button(item.title, role: .destructive) {
                    perform(item)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .action, .destructive, .sheet:
            Button(role: item.role) {
                select(item)
            } label: {
                DeveloperMenuLabel(title: item.title, subtitle: item.subtitle)
            }
        case .toggle(let get, let set):
            DeveloperMenuToggle(item: item, get: get, set: set)
        case .link(let destination):
            NavigationLink {
                destination()
                    .navigationTitle(item.title)
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                DeveloperMenuLabel(title: item.title, subtitle: item.subtitle)
            }
        case .menu(let sections):
            Menu {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    Section {
                        ForEach(section.items) { option in
                            Button(role: option.role) {
                                select(option)
                            } label: {
                                DeveloperMenuLabel(title: option.title, subtitle: option.subtitle)
                            }
                        }
                    } header: {
                        if let title = section.title {
                            Text(title)
                        }
                    }
                }
            } label: {
                HStack {
                    DeveloperMenuLabel(title: item.title, subtitle: item.subtitle)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
                .contentShape(Rectangle())
            }
        case .value(let value):
            Button {
                guard let value else { return }
                UIPasteboard.general.string = value
                Toast.show("\(item.title) copied")
            } label: {
                LabeledContent {
                    Text(value ?? "None")
                        .font(.footnote.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                } label: {
                    Text(item.title)
                        .foregroundStyle(Color.primary)
                }
            }
            .disabled(value == nil)
        case .custom(let content):
            content()
        }
    }

    private var isConfirming: Binding<Bool> {
        Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } })
    }

    private func select(_ item: DeveloperMenuItem) {
        switch item.kind {
        case .destructive:
            confirming = item
        case .sheet:
            presented = item
        default:
            perform(item)
        }
    }

    private func perform(_ selected: DeveloperMenuItem) {
        switch selected.kind {
        case .action(let perform), .destructive(let perform):
            perform()
            Toast.show(selected.id == item.id ? "Done: \(item.title)" : "Done: \(item.title) › \(selected.title)")
        default:
            break
        }
    }
}

private extension DeveloperMenuItem {
    var role: ButtonRole? {
        if case .destructive = kind {
            return .destructive
        }
        return nil
    }
}

private struct DeveloperMenuLabel: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

private struct DeveloperMenuToggle: View {
    let item: DeveloperMenuItem
    let set: @MainActor (Bool) -> Void

    @State private var isOn: Bool

    init(item: DeveloperMenuItem, get: @MainActor () -> Bool, set: @escaping @MainActor (Bool) -> Void) {
        self.item = item
        self.set = set
        _isOn = State(initialValue: get())
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            DeveloperMenuLabel(title: item.title, subtitle: item.subtitle)
        }
        .onChange(of: isOn) { _, newValue in
            set(newValue)
        }
    }
}
