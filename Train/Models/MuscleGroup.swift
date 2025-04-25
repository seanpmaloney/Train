import Foundation
import SwiftUI

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
}
