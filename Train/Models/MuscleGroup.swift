import Foundation
import SwiftUI

/// Guidelines for training volume by muscle group, including evidence-based ranges
struct TrainingVolumeGuidelines {
    /// Range of weekly sets recommended for maintenance
    let maintenanceSetsRange: ClosedRange<Int>
    
    /// Range of weekly sets recommended for hypertrophy (muscle growth)
    let hypertrophySetsRange: ClosedRange<Int>
    
    /// Description explaining the recommendation
    let description: String
    
    /// Source URL for evidence backing the recommendation
    let source: URL
    
    // Convenience computed properties
    var minMaintenanceSets: Int { maintenanceSetsRange.lowerBound }
    var maxMaintenanceSets: Int { maintenanceSetsRange.upperBound }
    var minHypertrophySets: Int { hypertrophySetsRange.lowerBound }
    var maxHypertrophySets: Int { hypertrophySetsRange.upperBound }
}

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest, back, quads, hamstrings, glutes, calves, biceps, triceps, shoulders, abs, forearms, obliques, lowerBack, traps, neck, unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .shoulders: return "Shoulders"
        case .abs: return "Abs"
        case .forearms: return "Forearms"
        case .obliques: return "Obliques"
        case .lowerBack: return "Lower Back"
        case .traps: return "Traps"
        case .neck: return "Neck"
        case .unknown: return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .chest: return AppStyle.MuscleColors.chest
        case .back: return AppStyle.MuscleColors.back
        case .quads: return AppStyle.MuscleColors.quads
        case .hamstrings: return AppStyle.MuscleColors.hamstrings
        case .glutes: return AppStyle.MuscleColors.glutes
        case .calves: return AppStyle.MuscleColors.calves
        case .biceps: return AppStyle.MuscleColors.biceps
        case .triceps: return AppStyle.MuscleColors.triceps
        case .shoulders: return AppStyle.MuscleColors.shoulders
        case .abs: return AppStyle.MuscleColors.abs
        case .forearms: return AppStyle.MuscleColors.forearms
        case .obliques: return AppStyle.MuscleColors.obliques
        case .lowerBack: return AppStyle.MuscleColors.lowerBack
        case .traps: return AppStyle.MuscleColors.traps
        case .neck: return AppStyle.MuscleColors.neck
        case .unknown: return AppStyle.Colors.textSecondary
        }
    }
    
    /// Evidence-based training volume guidelines for maintenance and hypertrophy
    var trainingGuidelines: TrainingVolumeGuidelines {
        switch self {
        case .chest:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 1...3,
                hypertrophySetsRange: 10...20,
                description: "Maintain chest size with 1–3 hard sets/week; optimal growth around 10–20 sets spread across ≥2 sessions.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/30558493/")!
            )
        case .back:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 1...3,
                hypertrophySetsRange: 12...25,
                description: "Back/lats tolerate & often require higher volume; ~12–25 weekly sets maximizes hypertrophy, while 1–3 hard sets preserves size.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/34106993/")!
            )
        case .quads:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 1...3,
                hypertrophySetsRange: 10...20,
                description: "Quadriceps grow well with ~10–20 weekly sets; just 1–3 heavy sets (e.g., squats) can maintain mass.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/35986141/")!
            )
        case .hamstrings:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 1...3,
                hypertrophySetsRange: 6...12,
                description: "Deep‑stretch lifts make hamstrings responsive at moderate volume (~6–12 sets); 1–3 heavy sets/week maintain.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/34106993/")!
            )
        case .glutes:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 1...3,
                hypertrophySetsRange: 6...15,
                description: "Compound lower‑body work often suffices; add 6–15 direct sets/week if glute growth is a priority.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/35266923/")!
            )
        case .calves:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 2...3,
                hypertrophySetsRange: 12...18,
                description: "Calves usually need higher direct volume (~12–18 sets) for growth; 2–3 hard sets/week maintains size.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/31860526/")!
            )
        case .biceps:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 1...2,
                hypertrophySetsRange: 8...15,
                description: "Biceps grow with 8–15 total sets (including indirect work); 1–2 near‑failure sets preserve muscle.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/31094288/")!
            )
        case .triceps:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 1...3,
                hypertrophySetsRange: 10...20,
                description: "Triceps often benefit from the higher end of volume (10–20 sets); only 1–3 sets/week needed for maintenance.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/35473018/")!
            )
        case .shoulders:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 1...3,
                hypertrophySetsRange: 10...20,
                description: "Including indirect work, 10–20 total sets/week maximizes delt growth; 1–3 heavy sets suffice to maintain.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/35075938/")!
            )
        case .abs, .obliques:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 2...4,
                hypertrophySetsRange: 8...16,
                description: "General guideline: core muscles respond well to 8–16 direct sets/week; 2–4 sets maintain.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/34106993/")!
            )
        case .forearms:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 0...1,
                hypertrophySetsRange: 8...15,
                description: "The forearm muscles are involved in almost every pulling or gripping exercise, so they often grow from indirect work. For dedicated growth use 8–15 direct sets/week. Virtually zero direct sets needed for maintenance.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/31308713/")!
            )
        case .lowerBack:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 1...3,
                hypertrophySetsRange: 10...12,
                description: "Lower‑back (erector spinae) growth responds well to ~10‑12 sets/week (incl. deadlifts, extensions); 1–3 hard sets maintain size.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/34106993/")!
            )
        case .traps:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 0...4,
                hypertrophySetsRange: 10...20,
                description: "Traps receive indirect work from pulls; ~10‑20 total sets/week (direct + indirect) maximizes hypertrophy, while ≤4 hard sets (or heavy compound lifts alone) preserve size.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/34106993/")!
            )
        case .neck:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 1...3,
                hypertrophySetsRange: 8...12,
                description: "Direct neck work (~8‑12 sets/week split across flexion, extension, lateral) needed for growth; 1–3 challenging sets/week sufficient to maintain.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/9286837/")!
            )
        case .unknown:
            return TrainingVolumeGuidelines(
                maintenanceSetsRange: 2...4,
                hypertrophySetsRange: 8...16,
                description: "General guideline derived from volume dose‑response reviews where muscle‑specific data are limited.",
                source: URL(string: "https://pubmed.ncbi.nlm.nih.gov/34106993/")!
            )
        }
    }
}
