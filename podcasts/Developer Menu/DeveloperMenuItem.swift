import SwiftUI

struct DeveloperMenuPage: Identifiable {
    let title: String
    let systemImage: String
    let sections: [DeveloperMenuSection]

    var id: String { title }
}

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
        case value(String?)
        case custom(@MainActor () -> AnyView)
    }

    let title: String
    var subtitle: String?
    let kind: Kind

    var id: String { title }

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

    static func value(_ title: String, _ value: String?) -> Self {
        Self(title: title, kind: .value(value))
    }

    static func custom<Content: View>(_ title: String, @ViewBuilder content: @escaping @MainActor () -> Content) -> Self {
        Self(title: title, kind: .custom { AnyView(content()) })
    }
}

struct DeveloperMenuPageView: View {
    let page: DeveloperMenuPage

    var body: some View {
        List {
            ForEach(Array(page.sections.enumerated()), id: \.offset) { _, section in
                DeveloperMenuSectionView(section: section)
            }
        }
        .navigationTitle(page.title)
        .navigationBarTitleDisplayMode(.inline)
        .miniPlayerSafeAreaInset()
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

    @State private var isPresented = false
    @State private var isConfirming = false

    var body: some View {
        switch item.kind {
        case .action(let perform):
            Button {
                perform()
                Toast.show("Done: \(item.title)")
            } label: {
                label
            }
        case .destructive(let perform):
            Button(role: .destructive) {
                isConfirming = true
            } label: {
                label
            }
            .confirmationDialog(item.title, isPresented: $isConfirming, titleVisibility: .visible) {
                Button(item.title, role: .destructive) {
                    perform()
                    Toast.show("Done: \(item.title)")
                }
            }
        case .toggle(let get, let set):
            DeveloperMenuToggle(item: item, get: get, set: set)
        case .sheet(let content):
            Button {
                isPresented = true
            } label: {
                label
            }
            .sheet(isPresented: $isPresented) {
                content { isPresented = false }
                    .setupDefaultEnvironment()
            }
        case .link(let destination):
            NavigationLink {
                destination()
                    .navigationTitle(item.title)
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                label
            }
        case .value(let value):
            Button {
                guard let value else { return }
                UIPasteboard.general.string = value
                Toast.show("\(item.title) copied")
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .foregroundStyle(Color.primary)
                    Text(value ?? "None")
                        .font(.footnote.monospaced())
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .disabled(value == nil)
        case .custom(let content):
            content()
        }
    }

    private var label: some View {
        DeveloperMenuLabel(title: item.title, subtitle: item.subtitle)
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
                    .foregroundStyle(.secondary)
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
