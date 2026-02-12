import Foundation
import Observation

enum AgeBand: String, CaseIterable, Codable, Identifiable {
    case fourToFive = "4-5"
    case sixToSeven = "6-7"
    case eightToNine = "8-9"
    case tenToEleven = "10-11"
    case twelvePlus = "12+"
    case allAges = "All Ages"

    var id: String { rawValue }

    var displayName: String { rawValue }
}

struct FamilyProfile: Identifiable, Codable {
	var id: UUID
	var name: String
	var ageBand: AgeBand
	var allowedDeckIDs: [String]
	var preferredVoiceIdentifier: String
	var speechEnabled: Bool
	var selectedGroupID: String?
	var selectedDeckID: String?
	var showSplash: Bool
	var showRecommendedRow: Bool
	var showProgressBar: Bool
	var showVoiceBadge: Bool

	init(
		id: UUID,
		name: String,
		ageBand: AgeBand,
		allowedDeckIDs: [String],
		preferredVoiceIdentifier: String = "",
		speechEnabled: Bool = false,
		selectedGroupID: String? = nil,
		selectedDeckID: String? = nil,
		showSplash: Bool = true,
		showRecommendedRow: Bool = true,
		showProgressBar: Bool = true,
		showVoiceBadge: Bool = true
	) {
		self.id = id
		self.name = name
		self.ageBand = ageBand
		self.allowedDeckIDs = allowedDeckIDs
		self.preferredVoiceIdentifier = preferredVoiceIdentifier
		self.speechEnabled = speechEnabled
		self.selectedGroupID = selectedGroupID
		self.selectedDeckID = selectedDeckID
		self.showSplash = showSplash
		self.showRecommendedRow = showRecommendedRow
		self.showProgressBar = showProgressBar
		self.showVoiceBadge = showVoiceBadge
	}

	private enum CodingKeys: String, CodingKey {
		case id
		case name
		case ageBand
		case allowedDeckIDs
		case preferredVoiceIdentifier
		case speechEnabled
		case selectedGroupID
		case selectedDeckID
		case showSplash
		case showRecommendedRow
		case showProgressBar
		case showVoiceBadge
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(UUID.self, forKey: .id)
		name = try container.decode(String.self, forKey: .name)
		ageBand = try container.decode(AgeBand.self, forKey: .ageBand)
		allowedDeckIDs = try container.decodeIfPresent([String].self, forKey: .allowedDeckIDs) ?? []
		preferredVoiceIdentifier = try container.decodeIfPresent(String.self, forKey: .preferredVoiceIdentifier) ?? ""
		speechEnabled = try container.decodeIfPresent(Bool.self, forKey: .speechEnabled) ?? false
		selectedGroupID = try container.decodeIfPresent(String.self, forKey: .selectedGroupID)
		selectedDeckID = try container.decodeIfPresent(String.self, forKey: .selectedDeckID)
		showSplash = try container.decodeIfPresent(Bool.self, forKey: .showSplash) ?? true
		showRecommendedRow = try container.decodeIfPresent(Bool.self, forKey: .showRecommendedRow) ?? true
		showProgressBar = try container.decodeIfPresent(Bool.self, forKey: .showProgressBar) ?? true
		showVoiceBadge = try container.decodeIfPresent(Bool.self, forKey: .showVoiceBadge) ?? true
	}
}

struct FamilySettings: Codable {
    var profiles: [FamilyProfile]
    var selectedProfileID: UUID?
    var deckAgeBands: [String: AgeBand]
}

@Observable
final class FamilyStore {
    var profiles: [FamilyProfile] = []
    private(set) var selectedProfileID: UUID?
    private(set) var deckAgeBands: [String: AgeBand] = [:]
    private(set) var changeToken: UUID = UUID()

    private let fileName = "family_profiles.json"

    func load() {
        guard let url = documentsDirectory()?.appendingPathComponent(fileName),
              let data = try? Data(contentsOf: url),
              let settings = try? JSONDecoder().decode(FamilySettings.self, from: data) else {
            seedDefaults()
            return
        }

        profiles = settings.profiles
        selectedProfileID = settings.selectedProfileID ?? settings.profiles.first?.id
        deckAgeBands = settings.deckAgeBands
        ensureDefaultsIfNeeded()
    }

    func save() {
        guard let url = documentsDirectory()?.appendingPathComponent(fileName) else { return }
        let settings = FamilySettings(
            profiles: profiles,
            selectedProfileID: selectedProfileID,
            deckAgeBands: deckAgeBands
        )
        guard let data = try? JSONEncoder().encode(settings) else { return }
        try? data.write(to: url, options: .atomic)
        changeToken = UUID()
    }

    var currentProfile: FamilyProfile? {
        if let selectedProfileID, let profile = profiles.first(where: { $0.id == selectedProfileID }) {
            return profile
        }
        return profiles.first
    }

    func setSelectedProfileID(_ id: UUID?) {
        selectedProfileID = id
        save()
    }

    func updateCurrentProfileVoice(_ identifier: String) {
        guard var profile = currentProfile else { return }
        profile.preferredVoiceIdentifier = identifier
        updateProfile(profile)
    }

    func updateCurrentProfileSpeechEnabled(_ enabled: Bool) {
        guard var profile = currentProfile else { return }
        profile.speechEnabled = enabled
        updateProfile(profile)
    }

	func addProfile(activate: Bool = true) {
		let nextIndex = profiles.count + 1
		let newProfile = FamilyProfile(
			id: UUID(),
			name: "Kid \(nextIndex)",
			ageBand: .fourToFive,
			allowedDeckIDs: [],
			preferredVoiceIdentifier: "",
			speechEnabled: false,
			selectedGroupID: nil,
			selectedDeckID: nil,
			showSplash: true,
			showRecommendedRow: true,
			showProgressBar: true,
			showVoiceBadge: true
		)
        profiles.append(newProfile)
        if activate {
            selectedProfileID = newProfile.id
        }
        save()
    }

    func removeProfile(id: UUID) {
        guard profiles.count > 1 else { return }
        profiles.removeAll { $0.id == id }
        if selectedProfileID == id {
            selectedProfileID = profiles.first?.id
        }
        save()
    }

    func updateProfile(_ profile: FamilyProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        save()
    }

    func updateProfileVoice(_ identifier: String, for profileID: UUID) {
        guard var profile = profiles.first(where: { $0.id == profileID }) else { return }
        profile.preferredVoiceIdentifier = identifier
        updateProfile(profile)
    }

	func updateProfileSpeechEnabled(_ enabled: Bool, for profileID: UUID) {
		guard var profile = profiles.first(where: { $0.id == profileID }) else { return }
		profile.speechEnabled = enabled
		updateProfile(profile)
	}

	func updateProfileSelection(groupID: String?, deckID: String?, for profileID: UUID) {
		guard var profile = profiles.first(where: { $0.id == profileID }) else { return }
		profile.selectedGroupID = groupID
		profile.selectedDeckID = deckID
		updateProfile(profile)
	}

	func updateProfileUIPreferences(
		showSplash: Bool,
		showRecommendedRow: Bool,
		showProgressBar: Bool,
		showVoiceBadge: Bool,
		for profileID: UUID
	) {
		guard var profile = profiles.first(where: { $0.id == profileID }) else { return }
		profile.showSplash = showSplash
		profile.showRecommendedRow = showRecommendedRow
		profile.showProgressBar = showProgressBar
		profile.showVoiceBadge = showVoiceBadge
		updateProfile(profile)
	}

    func setDeckAgeBand(_ band: AgeBand, for deckID: String) {
        deckAgeBands[deckID] = band
        save()
    }

    func deckAgeBand(for deckID: String) -> AgeBand {
        deckAgeBands[deckID] ?? .allAges
    }

    func allowList(for profile: FamilyProfile) -> Set<String> {
        Set(profile.allowedDeckIDs)
    }

    func allows(deckID: String, for profile: FamilyProfile) -> Bool {
        let allowed = allowList(for: profile)
        if allowed.isEmpty {
            return true
        }
        return allowed.contains(deckID)
    }

    func matchesAge(deckID: String, for profile: FamilyProfile) -> Bool {
        let band = deckAgeBand(for: deckID)
        if band == .allAges {
            return true
        }
        return band == profile.ageBand
    }

	private func seedDefaults() {
		let defaultProfile = FamilyProfile(
			id: UUID(),
			name: "Kid",
			ageBand: .fourToFive,
			allowedDeckIDs: [],
			preferredVoiceIdentifier: "",
			speechEnabled: false,
			selectedGroupID: nil,
			selectedDeckID: nil,
			showSplash: true,
			showRecommendedRow: true,
			showProgressBar: true,
			showVoiceBadge: true
		)
        profiles = [defaultProfile]
        selectedProfileID = defaultProfile.id
        deckAgeBands = [:]
        save()
    }

    private func ensureDefaultsIfNeeded() {
        if profiles.isEmpty {
            seedDefaults()
            return
        }
        if selectedProfileID == nil {
            selectedProfileID = profiles.first?.id
        }
    }

    private func documentsDirectory() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    }
}
