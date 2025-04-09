import Foundation

class MovementEntity: ObservableObject, Identifiable, Codable {
    let id: UUID = UUID()
    @Published var name: String
    @Published var notes: String?
    @Published var videoURL: String?
    @Published var muscleGroups: [MuscleGroupEntity] = []

    init(name: String, notes: String? = nil, videoURL: String? = nil) {
        self.name = name
        self.notes = notes
        self.videoURL = videoURL
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, notes, videoURL, muscleGroups
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        videoURL = try container.decodeIfPresent(String.self, forKey: .videoURL)
        muscleGroups = try container.decode([MuscleGroupEntity].self, forKey: .muscleGroups)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(videoURL, forKey: .videoURL)
        try container.encode(muscleGroups, forKey: .muscleGroups)
    }
} 
