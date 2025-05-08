import Foundation

/// Enum representing all available movement types in the app
enum MovementType: String, CaseIterable, Codable, Identifiable {
    // Chest
    case barbellBenchPress
    case dumbbellInclinePress
    case pushUps
    case cableFlyes
    case machinePecDeck
    case dumbbellBenchPress
    case cableChestFly
    case dips
    
    // Back
    case barbellDeadlift
    case pullUps
    case bentOverRow
    case latPulldown
    case seatedCableRow
    case dumbbellRow
    case cablePullover
    case chinUps
    case uprightRow
    
    // Legs
    case barbellBackSquat
    case romanianDeadlift
    case legPress
    case bulgarianSplitSquat
    case standingCalfRaise
    case legExtension
    case lyingLegCurl
    case gobletSquat
    case sledPush
    case barbellFrontSquat
    
    // Shoulders
    case overheadPress
    case lateralRaise
    case facePull
    case frontRaise
    case arnoldPress
    case machineLateralRaise
    
    // Arms
    case barbellCurl
    case tricepPushdown
    case hammerCurl
    case skullCrushers
    case preacherCurl
    case concentrationCurl
    case overheadTricepExtension
    case cableCurl
    case dumbbellCurl
    
    // Core
    case cableCrunch
    case plank
    case russianTwist
    case legRaise
    case abRollout
    
    // Fallback for unknown movements
    case unknown
    
    var id: String { displayName }
    
    /// Returns the display name of the movement
    var displayName: String {
        // Convert camelCase to Title Case with spaces
        switch self {
        case .barbellBenchPress: return "Barbell Bench Press"
        case .dumbbellInclinePress: return "Dumbbell Incline Press"
        case .dumbbellCurl: return "Dumbbell Curl"
        case .pushUps: return "Push-Ups"
        case .cableFlyes: return "Cable Flyes"
        case .machinePecDeck: return "Machine Pec Deck"
        case .dumbbellBenchPress: return "Dumbbell Bench Press"
        case .cableChestFly: return "Cable Chest Fly"
        case .dips: return "Dips"
        case .barbellDeadlift: return "Barbell Deadlift"
        case .pullUps: return "Pull-Ups"
        case .bentOverRow: return "Bent Over Row"
        case .latPulldown: return "Lat Pulldown"
        case .seatedCableRow: return "Seated Cable Row"
        case .dumbbellRow: return "Dumbbell Row"
        case .cablePullover: return "Cable Pullover"
        case .chinUps: return "Chin-Ups"
        case .uprightRow: return "Upright Row"
        case .barbellBackSquat: return "Barbell Back Squat"
        case .romanianDeadlift: return "Romanian Deadlift"
        case .legPress: return "Leg Press"
        case .bulgarianSplitSquat: return "Bulgarian Split Squat"
        case .standingCalfRaise: return "Standing Calf Raise"
        case .legExtension: return "Leg Extension"
        case .lyingLegCurl: return "Lying Leg Curl"
        case .gobletSquat: return "Goblet Squat"
        case .sledPush: return "Sled Push"
        case .barbellFrontSquat: return "Barbell Front Squat"
        case .overheadPress: return "Overhead Press"
        case .lateralRaise: return "Lateral Raise"
        case .facePull: return "Face Pull"
        case .frontRaise: return "Front Raise"
        case .arnoldPress: return "Arnold Press"
        case .machineLateralRaise: return "Machine Lateral Raise"
        case .barbellCurl: return "Barbell Curl"
        case .tricepPushdown: return "Tricep Pushdown"
        case .hammerCurl: return "Hammer Curl"
        case .skullCrushers: return "Skull Crushers"
        case .preacherCurl: return "Preacher Curl"
        case .concentrationCurl: return "Concentration Curl"
        case .overheadTricepExtension: return "Overhead Tricep Extension"
        case .cableCurl: return "Cable Curl"
        case .cableCrunch: return "Cable Crunch"
        case .plank: return "Plank"
        case .russianTwist: return "Russian Twist"
        case .legRaise: return "Leg Raise"
        case .abRollout: return "Ab Rollout"
        case .unknown: return "Unknown Movement"
        }
    }
}

