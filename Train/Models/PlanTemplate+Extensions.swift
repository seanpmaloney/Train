import Foundation

extension PlanTemplate {
    /// Finds a template by its ID
    static func findTemplate(with id: String) -> PlanTemplate? {
        return templates.first { $0.id == id }
    }
}
