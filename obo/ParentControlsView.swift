import SwiftUI
import AVFoundation

struct ParentControlsView: View {
    let groups: [TopicGroup]
    let visibleGroups: [TopicGroup]
    @Binding var selectedGroupIndex: Int
    @Binding var selectedDeckIndex: Int
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

            Section("Profile Settings") {
                NavigationLink("Active Category") {
                    FamilyActiveCategoryView(
                        visibleGroups: visibleGroups,
                        selectedGroupIndex: $selectedGroupIndex,
                        selectedDeckIndex: $selectedDeckIndex,
                        profile: editingProfile,
                        familyStore: familyStore
                    )
                }

                NavigationLink("Voice & Speech") {
                    FamilySpeechView(
                        profileName: editingProfile?.name ?? "Profile",
                        availableVoices: availableVoices,
                        isSpeechEnabled: editingSpeechEnabledBinding,
                        selectedVoiceIdentifier: editingVoiceBinding
                    )
                }

                NavigationLink("UI Preferences") {
                    FamilyUIPreferencesView(
                        profileName: editingProfile?.name ?? "Profile",
                        showSplash: editingShowSplashBinding,
                        showRecommendedRow: editingShowRecommendedRowBinding,
                        showProgressBar: editingShowProgressBarBinding,
                        showVoiceBadge: editingShowVoiceBadgeBinding
                    )
                }
            }

            Section("Family Management") {
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

            Section("Source") {
                Text(sourceDescription)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Family Hub")
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

    private var editingVoiceBinding: Binding<String> {
        Binding(
            get: {
                guard let profile = editingProfile else { return selectedVoiceIdentifier }
                if profile.preferredVoiceIdentifier.isEmpty {
                    return selectedVoiceIdentifier
                }
                return profile.preferredVoiceIdentifier
            },
            set: { newValue in
                if let profileID = editingProfile?.id {
                    familyStore.updateProfileVoice(newValue, for: profileID)
                }
                if profileIDMatchesCurrent {
                    selectedVoiceIdentifier = newValue
                }
            }
        )
    }

    private var editingSpeechEnabledBinding: Binding<Bool> {
        Binding(
            get: { editingProfile?.speechEnabled ?? isSpeechEnabled },
            set: { newValue in
                if let profileID = editingProfile?.id {
                    familyStore.updateProfileSpeechEnabled(newValue, for: profileID)
                }
                if profileIDMatchesCurrent {
                    isSpeechEnabled = newValue
                }
            }
        )
    }

    private var profileIDMatchesCurrent: Bool {
        guard let editingID = editingProfile?.id else { return false }
        return editingID == familyStore.currentProfile?.id
    }

    private var editingShowSplashBinding: Binding<Bool> {
        Binding(
            get: { editingProfile?.showSplash ?? true },
            set: { newValue in
                updateEditingUIPreferences(showSplash: newValue)
            }
        )
    }

    private var editingShowRecommendedRowBinding: Binding<Bool> {
        Binding(
            get: { editingProfile?.showRecommendedRow ?? true },
            set: { newValue in
                updateEditingUIPreferences(showRecommendedRow: newValue)
            }
        )
    }

    private var editingShowProgressBarBinding: Binding<Bool> {
        Binding(
            get: { editingProfile?.showProgressBar ?? true },
            set: { newValue in
                updateEditingUIPreferences(showProgressBar: newValue)
            }
        )
    }

    private var editingShowVoiceBadgeBinding: Binding<Bool> {
        Binding(
            get: { editingProfile?.showVoiceBadge ?? true },
            set: { newValue in
                updateEditingUIPreferences(showVoiceBadge: newValue)
            }
        )
    }

    private func updateEditingUIPreferences(
        showSplash: Bool? = nil,
        showRecommendedRow: Bool? = nil,
        showProgressBar: Bool? = nil,
        showVoiceBadge: Bool? = nil
    ) {
        guard let profile = editingProfile else { return }
        let updatedSplash = showSplash ?? profile.showSplash
        let updatedRecommended = showRecommendedRow ?? profile.showRecommendedRow
        let updatedProgress = showProgressBar ?? profile.showProgressBar
        let updatedVoiceBadge = showVoiceBadge ?? profile.showVoiceBadge
        familyStore.updateProfileUIPreferences(
            showSplash: updatedSplash,
            showRecommendedRow: updatedRecommended,
            showProgressBar: updatedProgress,
            showVoiceBadge: updatedVoiceBadge,
            for: profile.id
        )
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

}

private struct FamilyActiveCategoryView: View {
    let visibleGroups: [TopicGroup]
    @Binding var selectedGroupIndex: Int
    @Binding var selectedDeckIndex: Int
    let profile: FamilyProfile?
    @Bindable var familyStore: FamilyStore

    var body: some View {
        List {
            if let profile {
                Section {
                    Text("Applies to \(profile.name).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(visibleGroups.indices, id: \.self) { index in
                Button {
                    setSelection(groupIndex: index)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isSelected(groupIndex: index) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected(groupIndex: index) ? Color.accentColor : .secondary)

                        Text(visibleGroups[index].title)
                            .font(.headline)

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }

            if let groupIndex = selectedGroupIndexForProfile,
               visibleGroups.indices.contains(groupIndex) {
                Section("Active Deck") {
                    let decks = visibleGroups[groupIndex].decks
                    ForEach(decks) { deck in
                        Button {
                            setDeckSelection(deckID: deck.id, groupIndex: groupIndex)
                        } label: {
                            HStack {
                                Image(systemName: isSelected(deckID: deck.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(isSelected(deckID: deck.id) ? Color.accentColor : .secondary)
                                Text(deck.title)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Active Category")
    }

    private func setSelection(groupIndex: Int) {
        guard visibleGroups.indices.contains(groupIndex) else { return }
        let group = visibleGroups[groupIndex]
        let deckID = group.decks.first?.id
        if let profileID = profile?.id {
            familyStore.updateProfileSelection(groupID: group.id, deckID: deckID, for: profileID)
        }

        if profile?.id == familyStore.currentProfile?.id {
            selectedGroupIndex = groupIndex
            selectedDeckIndex = 0
        }
    }

    private func setDeckSelection(deckID: String, groupIndex: Int) {
        guard visibleGroups.indices.contains(groupIndex) else { return }
        let group = visibleGroups[groupIndex]
        if let profileID = profile?.id {
            familyStore.updateProfileSelection(groupID: group.id, deckID: deckID, for: profileID)
        }

        if profile?.id == familyStore.currentProfile?.id,
           let deckIndex = group.decks.firstIndex(where: { $0.id == deckID }) {
            selectedGroupIndex = groupIndex
            selectedDeckIndex = deckIndex
        }
    }

    private func isSelected(groupIndex: Int) -> Bool {
        guard visibleGroups.indices.contains(groupIndex) else { return false }
        let groupID = visibleGroups[groupIndex].id
        if let profileGroupID = profile?.selectedGroupID {
            return profileGroupID == groupID
        }
        return selectedGroupIndex == groupIndex
    }

    private func isSelected(deckID: String) -> Bool {
        if let profileDeckID = profile?.selectedDeckID {
            return profileDeckID == deckID
        }
        if let groupIndex = selectedGroupIndexForProfile,
           visibleGroups.indices.contains(groupIndex) {
            let decks = visibleGroups[groupIndex].decks
            if let deckIndex = decks.firstIndex(where: { $0.id == deckID }) {
                return selectedDeckIndex == deckIndex
            }
        }
        return false
    }

    private var selectedGroupIndexForProfile: Int? {
        if let profileGroupID = profile?.selectedGroupID,
           let index = visibleGroups.firstIndex(where: { $0.id == profileGroupID }) {
            return index
        }
        if visibleGroups.indices.contains(selectedGroupIndex) {
            return selectedGroupIndex
        }
        return nil
    }
}

private struct FamilySpeechView: View {
    let profileName: String
    let availableVoices: [AVSpeechSynthesisVoice]
    @Binding var isSpeechEnabled: Bool
    @Binding var selectedVoiceIdentifier: String

    var body: some View {
        List {
            Section {
                Text("Applies to \(profileName).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
        }
        .navigationTitle("Voice & Speech")
    }
}

private struct FamilyUIPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    let profileName: String
    @Binding var showSplash: Bool
    @Binding var showRecommendedRow: Bool
    @Binding var showProgressBar: Bool
    @Binding var showVoiceBadge: Bool
    @AppStorage("forceOnboarding") private var forceOnboarding: Bool = false

    var body: some View {
        List {
            Section {
                Text("Applies to \(profileName).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("UI Preferences") {
                Toggle("Show launch splash", isOn: $showSplash)
                Toggle("Show recommended decks", isOn: $showRecommendedRow)
                Toggle("Show progress bar", isOn: $showProgressBar)
                Toggle("Show voice badge", isOn: $showVoiceBadge)
            }

            Section {
                Button("Run Onboarding") {
                    forceOnboarding = true
                    dismiss()
                }
            }
        }
        .navigationTitle("UI Preferences")
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
