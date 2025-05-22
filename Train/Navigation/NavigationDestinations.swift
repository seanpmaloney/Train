import Foundation
import SwiftUI

/// Navigation destinations for the app
enum NavigationDestination: Hashable {
    case templatePicker
    case adaptivePlanSetup
    case generatedPlanEditor(planId: UUID)
    case planEditor(templateId: String?)
    case planDetail(planId: UUID)
}
