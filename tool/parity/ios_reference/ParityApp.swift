import SwiftUI

// MARK: - Models
struct ContactItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var title: String
    var company: String
    var phone: String
    var email: String
    var isEmergency: Bool = false
    var isFavorite: Bool = false
    var gradientColors: [Color] = [.blue, .purple]
}

// MARK: - App Entrypoint
@main
struct ParityApp: App {
    var body: some Scene {
        WindowGroup {
            ParityTabView()
        }
    }
}

// MARK: - Tab View Host
struct ParityTabView: View {
    @State private var selectedTab: Int = {
        if let idx = CommandLine.arguments.firstIndex(of: "-tab"),
           idx + 1 < CommandLine.arguments.count,
           let val = Int(CommandLine.arguments[idx + 1]) {
            return val
        }
        return 0
    }()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContactsSwipeParityView()
                .tabItem {
                    Label("Swipe & Menu", systemImage: "hand.draw")
                }
                .tag(0)
            
            DisclosureParityView()
                .tabItem {
                    Label("Disclosure", systemImage: "chevron.down.circle")
                }
                .tag(1)
            
            EditModeParityView()
                .tabItem {
                    Label("Edit Mode", systemImage: "pencil.circle")
                }
                .tag(2)
            
            PickersParityView()
                .tabItem {
                    Label("Pickers", systemImage: "calendar")
                }
                .tag(3)
            
            ModalsAndNavParityView()
                .tabItem {
                    Label("Modals & Nav", systemImage: "arrow.up.forward.app")
                }
                .tag(4)
        }
    }
}

// MARK: - 1. Swipe Actions & Context Menu Parity
struct ContactsSwipeParityView: View {
    @State private var contacts = [
        ContactItem(name: "Alex Rivera", title: "Product Design Director", company: "Acme Corp", phone: "+1 (408) 555-0142", email: "alex@acme.io", isFavorite: true, gradientColors: [.blue, .cyan]),
        ContactItem(name: "Jordan Lee", title: "Engineering Lead", company: "Acme Corp", phone: "+1 (408) 555-0189", email: "jordan@acme.io", isFavorite: true, gradientColors: [.indigo, .purple]),
        ContactItem(name: "Taylor Brooks", title: "Creative Director", company: "Acme Corp", phone: "+1 (408) 555-0167", email: "taylor@acme.io", gradientColors: [.pink, .orange]),
        ContactItem(name: "Morgan Davis", title: "Principal Architect", company: "Acme Corp", phone: "+1 (408) 555-0123", email: "morgan@acme.io", gradientColors: [.purple, .blue])
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Swipe left for Delete / Flag. Swipe right to Pin. Long press any row for Context Menu with VIP Preview.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Section("Contacts (.swipeActions & .contextMenu)") {
                    ForEach($contacts) { $contact in
                        HStack(spacing: 14) {
                            Circle()
                                .fill(LinearGradient(colors: contact.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)
                                .overlay(Text(contact.name.prefix(1)).font(.headline).foregroundColor(.white))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.name).font(.system(size: 17, weight: .semibold))
                                Text(contact.title).font(.system(size: 13)).foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if contact.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 13))
                            }
                        }
                        .padding(.vertical, 4)
                        // Feature 4: Context Menu with Rich Preview
                        .contextMenu {
                            Button {
                                contact.isFavorite.toggle()
                            } label: {
                                Label(contact.isFavorite ? "Unfavorite" : "Favorite", systemImage: contact.isFavorite ? "star.slash" : "star.fill")
                            }
                            Button {
                                // Copy phone
                            } label: {
                                Label("Copy Phone", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                if let idx = contacts.firstIndex(where: { $0.id == contact.id }) {
                                    contacts.remove(at: idx)
                                }
                            } label: {
                                Label("Delete Contact", systemImage: "trash")
                            }
                        } preview: {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(LinearGradient(colors: contact.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 64, height: 64)
                                    .overlay(Text(contact.name.prefix(1)).font(.title).foregroundColor(.white))
                                Text(contact.name).font(.headline)
                                Text(contact.title).font(.subheadline).foregroundColor(.secondary)
                                Divider()
                                HStack {
                                    Image(systemName: "phone.fill").foregroundColor(.green)
                                    Text(contact.phone).font(.footnote)
                                }
                            }
                            .padding()
                            .frame(width: 240)
                        }
                        // Feature 1: Swipe Actions (Leading & Trailing)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if let idx = contacts.firstIndex(where: { $0.id == contact.id }) {
                                    contacts.remove(at: idx)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                contact.isFavorite.toggle()
                            } label: {
                                Label("Flag", systemImage: "flag.fill")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                contact.isFavorite.toggle()
                            } label: {
                                Label("Pin", systemImage: "pin.fill")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Swipe & Menu")
        }
    }
}

// MARK: - 2. Disclosure Group Parity
struct DisclosureParityView: View {
    @State private var isEmergencyExpanded = CommandLine.arguments.contains("-expandAll")
    @State private var isSocialsExpanded = CommandLine.arguments.contains("-expandAll")
    @State private var isPrivacyExpanded = CommandLine.arguments.contains("-expandAll")
    @State private var emergencyContactEnabled = true
    @State private var medicalNotes = "Allergies: Penicillin"
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("SwiftUI DisclosureGroup rotates chevron 90° upon expansion and insets dividers under child rows.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Section("Collapsible Sections (DisclosureGroup)") {
                    DisclosureGroup(isExpanded: $isEmergencyExpanded) {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle("Emergency Contact", isOn: $emergencyContactEnabled)
                            HStack {
                                Text("Blood Type")
                                Spacer()
                                Text("O+").foregroundColor(.secondary)
                            }
                            HStack {
                                Text("Medical ID")
                                Spacer()
                                Text("Active").foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 20))
                                .frame(width: 28)
                            VStack(alignment: .leading) {
                                Text("Emergency & Medical").font(.system(size: 17, weight: .semibold))
                                Text("Blood type, conditions, alerts").font(.system(size: 12)).foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    DisclosureGroup(isExpanded: $isSocialsExpanded) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill").foregroundColor(.blue)
                                Text("X / Twitter")
                                Spacer()
                                Text("@sdegenaar").foregroundColor(.secondary)
                            }
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right").foregroundColor(.purple)
                                Text("GitHub")
                                Spacer()
                                Text("sdegenaar").foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                                .frame(width: 28)
                            VStack(alignment: .leading) {
                                Text("Social Profiles & Handles").font(.system(size: 17, weight: .semibold))
                                Text("Online presence & profiles").font(.system(size: 12)).foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    DisclosureGroup(isExpanded: $isPrivacyExpanded) {
                        Toggle("AirDrop Discoverable", isOn: .constant(true))
                        Toggle("Share Name & Photo", isOn: .constant(true))
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 20))
                                .frame(width: 28)
                            VStack(alignment: .leading) {
                                Text("Privacy & AirDrop Sharing").font(.system(size: 17, weight: .semibold))
                                Text("Permissions and contact poster").font(.system(size: 12)).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Disclosure")
        }
    }
}

// MARK: - 3. Edit Mode & Reordering Parity
struct EditModeParityView: View {
    @State private var items = [
        "iPhone 18 Pro Glass Prototype",
        "Vision Pro Ultra Lensing",
        "Impeller Dual-Pipeline Shader",
        "Continuous Superellipse Squircle",
        "Adaptive Liquid Glass Chrome"
    ]
    @State private var editMode: EditMode = CommandLine.arguments.contains("-editOff") ? .inactive : .active
    @State private var selectedItems = Set<String>()
    
    var body: some View {
        NavigationStack {
            List(selection: $selectedItems) {
                Section {
                    Text("SwiftUI EditMode provides circular red delete buttons, inline Delete pills, 3-bar drag handles, and multi-selection.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Section("Edit Mode & Reordering (EditButton + ForEach)") {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Image(systemName: "app.dashed")
                                .foregroundColor(.blue)
                            Text(item)
                                .font(.system(size: 16))
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indices in
                        items.remove(atOffsets: indices)
                    }
                    .onMove { indices, newOffset in
                        items.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
            }
            .navigationTitle("Edit Mode")
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editMode.isEditing ? "Done" : "Edit") {
                        withAnimation {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - 4. Pickers Parity
struct PickersParityView: View {
    @State private var wheelDate = Date()
    @State private var compactDate = Date()
    @State private var graphicalDate = Date()
    @State private var multiDates: Set<DateComponents> = []
    
    var body: some View {
        NavigationStack {
            List {
                Section("Wheel Picker (DatePickerStyle.wheel)") {
                    DatePicker("Wheel", selection: $wheelDate, displayedComponents: [.date])
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
                
                Section("Compact Picker (DatePickerStyle.compact)") {
                    DatePicker("Date & Time", selection: $compactDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }
                
                Section("Graphical Calendar (DatePickerStyle.graphical)") {
                    DatePicker("Graphical", selection: $graphicalDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                }
                
                Section("Multi-Date Selection (MultiDatePicker)") {
                    MultiDatePicker("Select Dates", selection: $multiDates)
                    Text("Selected dates count: \(multiDates.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Pickers")
        }
    }
}

// MARK: - 5. Modals & Navigation Parity
struct ModalsAndNavParityView: View {
    @State private var isPresented = CommandLine.arguments.contains("-presentCover")
    @State private var navPath: NavigationPath = {
        var p = NavigationPath()
        if CommandLine.arguments.contains("-pushNav") { p.append("Level 1: Optics Architecture") }
        return p
    }()
    
    var body: some View {
        NavigationStack(path: $navPath) {
            List {
                Section("Full-Screen Cover (.fullScreenCover)") {
                    Button {
                        isPresented = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.forward.app.fill")
                                .foregroundColor(.blue)
                            Text("Present Full-Screen Cover")
                            Spacer()
                            Image(systemName: "chevron.right").font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Declarative Navigation (NavigationStack)") {
                    NavigationLink(value: "Level 1: Optics Architecture") {
                        Label("Optics Architecture", systemImage: "sparkles")
                    }
                    NavigationLink(value: "Level 1: Impeller Backend") {
                        Label("Impeller Backend", systemImage: "cpu")
                    }
                }
            }
            .navigationTitle("Modals & Nav")
            .navigationDestination(for: String.self) { value in
                VStack(spacing: 20) {
                    Text(value).font(.title2).bold()
                    Text("Demonstrates typed NavigationStack routing with back button and synchronized title.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    NavigationLink("Push Deeper", value: "\(value) -> Deeper")
                        .buttonStyle(.borderedProminent)
                }
                .navigationTitle("Detail")
                .navigationBarTitleDisplayMode(.inline)
            }
            .fullScreenCover(isPresented: $isPresented) {
                FullScreenSheetParityView(isPresented: $isPresented)
            }
        }
    }
}

struct FullScreenSheetParityView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "rectangle.portrait.and.arrow.forward")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("Full-Screen Cover Presentation")
                    .font(.title2)
                    .bold()
                
                Text("iOS fullScreenCover presentation style:\n• Slides in from bottom\n• Full viewport edge-to-edge\n• Rounded top corners on downward drag\n• Done/Cancel navigation bar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Modal Cover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .bold()
                }
            }
        }
    }
}
