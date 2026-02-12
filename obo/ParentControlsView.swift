import SwiftUI
import AVFoundation

struct ParentControlsView: View {
    let groups: [TopicGroup]
    let visibleGroups: [TopicGroup]
    @Binding var selectedGroupIndex: Int
    @Binding var selectedVoiceIdentifier: String
    let availableVoices: [AVSpeechSynthesisVoice]
    @Binding var isSpeechEnabled: Bool
    let sourceDescription: String
    @Bindable var familyStore: FamilyStore

    @State private var editingProfileID: UUID? = nil

    var body: some View {
        List {
            Section("Profile to Edit") {
                Picker("Edit Profile", selection: editingProfileBinding) {
                    ForEach(familyStore.profiles) { profile in
                        Text("\(profile.name) (\(profile.ageBand.displayName))")
                            .tag(profile.id)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Source") {
                Text(sourceDescription)
                    .foregroundStyle(.secondary)
            }

            Section("Active Category") {
                ForEach(visibleGroups.indices, id: \.self) { index in
                    Button {
                        selectedGroupIndex = index
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: selectedGroupIndex == index ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedGroupIndex == index ? Color.accentColor : .secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(visibleGroups[index].title)
                                    .font(.headline)

                                Text(categoryDescription(for: visibleGroups[index].title))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Speech") {
                Toggle("Enable Speech", isOn: $isSpeechEnabled)

                Picker("Voice", selection: $selectedVoiceIdentifier) {
                    ForEach(availableVoices, id: \.identifier) { voice in
                        Text("\(voice.name) (\(voice.language))")
                            .tag(voice.identifier)
                    }
                }
                .disabled(availableVoices.isEmpty)
            }

            NavigationLink("Profiles") {
                ParentProfilesView(familyStore: familyStore)
            }

            NavigationLink("Deck Access") {
                ParentDeckAccessView(
                    groups: groups,
                    profile: editingProfile,
                    deckAllowedBinding: deckAllowedBinding
                )
            }

            NavigationLink("Deck Ages") {
                ParentDeckAgesView(
                    groups: groups,
                    deckAgeBinding: deckAgeBinding
                )
            }
        }
        .navigationTitle("Caregiver Controls")
        .background(Color(.systemGroupedBackground))
        .onAppear {
            if editingProfileID == nil {
                editingProfileID = familyStore.currentProfile?.id
            }
        }
        .onChange(of: familyStore.profiles.map(\.id)) { _, newIDs in
            if let editingProfileID,
               !newIDs.contains(editingProfileID) {
                self.editingProfileID = familyStore.currentProfile?.id
            }
        }
    }

    private var editingProfile: FamilyProfile? {
        if let editingProfileID, let profile = familyStore.profiles.first(where: { $0.id == editingProfileID }) {
            return profile
        }
        return familyStore.currentProfile
    }

    private var editingProfileBinding: Binding<UUID> {
        Binding(
            get: { editingProfileID ?? familyStore.currentProfile?.id ?? UUID() },
            set: { newValue in
                editingProfileID = newValue
            }
        )
    }

    private func deckAllowedBinding(deckID: String, profile: FamilyProfile) -> Binding<Bool> {
        Binding(
            get: {
                let allowed = Set(profile.allowedDeckIDs)
                if allowed.isEmpty {
                    return true
                }
                return allowed.contains(deckID)
            },
            set: { isAllowed in
                var updatedProfile = profile
                var allowed = Set(profile.allowedDeckIDs)
                if allowed.isEmpty {
                    allowed = Set(allDeckIDs)
                }
                if isAllowed {
                    allowed.insert(deckID)
                } else {
                    allowed.remove(deckID)
                }
                if allowed.isEmpty {
                    updatedProfile.allowedDeckIDs = []
                } else {
                    updatedProfile.allowedDeckIDs = Array(allowed)
                }
                familyStore.updateProfile(updatedProfile)
            }
        )
    }

    private func deckAgeBinding(deckID: String) -> Binding<AgeBand> {
        Binding(
            get: { familyStore.deckAgeBand(for: deckID) },
            set: { newValue in
                familyStore.setDeckAgeBand(newValue, for: deckID)
            }
        )
    }

    private var allDeckIDs: [String] {
        groups.flatMap { $0.decks.map(\.id) }
    }

    private func categoryDescription(for title: String) -> String {
        switch title {
        case "STEM":
            return "Math, coding, and problem-solving."
        case "Life & Earth Science":
            return "Animals, weather, and the human body."
        case "Humanities & Arts":
            return "Reading, history, geography, and arts."
        default:
            return "More topics to explore."
        }
    }
}

    

private struct ParentProfilesView: View {
    @Bindable var familyStore: FamilyStore

    var body: some View {
        List {
            ForEach($familyStore.profiles) { $profile in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Name", text: $profile.name)
                            .textInputAutocapitalization(.words)
                            .onChange(of: profile.name) { _, _ in
                                familyStore.save()
                            }

                        Spacer()

                        if familyStore.profiles.count > 1 {
                            Button(role: .destructive) {
                                familyStore.removeProfile(id: profile.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }

                    Picker("Age", selection: $profile.ageBand) {
                        ForEach(AgeBand.allCases.filter { $0 != .allAges }) { band in
                            Text(band.displayName)
                                .tag(band)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: profile.ageBand) { _, _ in
                        familyStore.save()
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button("Add Profile") {
                familyStore.addProfile(activate: false)
            }
        }
        .navigationTitle("Profiles")
    }
}

private struct ParentDeckAccessView: View {
    let groups: [TopicGroup]
    let profile: FamilyProfile?
    let deckAllowedBinding: (String, FamilyProfile) -> Binding<Bool>

    var body: some View {
        List {
            if let profile {
                let allowed = Set(profile.allowedDeckIDs)
                if allowed.isEmpty {
                    Text("No decks selected — all decks are allowed.")
                        .foregroundStyle(.secondary)
                }

                ForEach(groups, id: \.id) { group in
                    Section(group.title) {
                        ForEach(group.decks) { deck in
                            Toggle(deck.title, isOn: deckAllowedBinding(deck.id, profile))
                        }
                    }
                }
            }
        }
        .navigationTitle("Deck Access")
    }
}

private struct ParentDeckAgesView: View {
    let groups: [TopicGroup]
    let deckAgeBinding: (String) -> Binding<AgeBand>

    var body: some View {
        List {
            ForEach(groups, id: \.id) { group in
                Section(group.title) {
                    ForEach(group.decks) { deck in
                        HStack {
                            Text(deck.title)
                            Spacer()
                            Picker("Age", selection: deckAgeBinding(deck.id)) {
                                ForEach(AgeBand.allCases) { band in
                                    Text(band.displayName)
                                        .tag(band)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
            }
        }
        .navigationTitle("Deck Ages")
    }
}
