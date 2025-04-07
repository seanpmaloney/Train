import Foundation

class MuscleGroupEntity: ObservableObject, Identifiable, Codable {
    let id: UUID = UUID()
    @Published var name: String
    @Published var notes: String?

    init(name: String, notes: String? = nil) {
        self.name = name
        self.notes = notes
    }
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case id, name, notes
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
} 
