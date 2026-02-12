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

    func addProfile(activate: Bool = true) {
        let nextIndex = profiles.count + 1
        let newProfile = FamilyProfile(
            id: UUID(),
            name: "Kid \(nextIndex)",
            ageBand: .fourToFive,
            allowedDeckIDs: []
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
            allowedDeckIDs: []
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
