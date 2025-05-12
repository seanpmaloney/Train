import SwiftUI

/// A sheet that displays detailed information about a movement
struct MovementInfoSheet: View {
    let movement: MovementEntity
    @Environment(\.dismiss) private var dismiss
    @State private var showingMovementPicker = false
    var onReplaceMovement: ((MovementEntity) -> Void)?
    
    init(movement: MovementEntity, onReplaceMovement: ((MovementEntity) -> Void)? = nil) {
        self.movement = movement
        self.onReplaceMovement = onReplaceMovement
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title and equipment type
                    VStack(alignment: .leading, spacing: 8) {
                        Text(movement.name)
                            .font(AppStyle.Typography.title())
                            .foregroundColor(AppStyle.Colors.textPrimary)
                        
                        Text(movement.equipment.rawValue)
                            .font(AppStyle.Typography.caption())
                            .foregroundColor(AppStyle.Colors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(AppStyle.Colors.surfaceTop)
                            )
                    }
                    
                    // Description
                    if let notes = movement.notes {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(AppStyle.Typography.headline())
                                .foregroundColor(AppStyle.Colors.textPrimary)
                            
                            Text(notes)
                                .font(AppStyle.Typography.body())
                                .foregroundColor(AppStyle.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                                .fill(AppStyle.Colors.surfaceTop)
                        )
                    }
                    
                    // Primary muscles
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Primary Muscles")
                            .font(AppStyle.Typography.headline())
                            .foregroundColor(AppStyle.Colors.textPrimary)
                        
                        // Simple wrapping HStack
                        HStack(spacing: 8) {
                            ForEach(movement.primaryMuscles, id: \.self) { muscle in
                                MusclePill(muscle: muscle)
                            }
                            Spacer()
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                            .fill(AppStyle.Colors.surfaceTop)
                    )
                    
                    // Secondary muscles (if any)
                    if !movement.secondaryMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Secondary Muscles")
                                .font(AppStyle.Typography.headline())
                                .foregroundColor(AppStyle.Colors.textPrimary)
                            
                            // Simple wrapping HStack
                            HStack(spacing: 8) {
                                ForEach(movement.secondaryMuscles, id: \.self) { muscle in
                                    MusclePill(muscle: muscle)
                                }
                                Spacer()
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                                .fill(AppStyle.Colors.surfaceTop)
                        )
                    }
                    
                    // Replace button
                    Button(action: {
                        // Only show the replacement button if the replacement callback exists
                        if onReplaceMovement != nil {
                            showingMovementPicker = true
                        } else {
                            print("Replace movement tapped, but no callback provided: \(movement.name)")
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.swap")
                            Text("Replace with Similar Movement")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppStyle.Layout.innerCardCornerRadius)
                                .fill(AppStyle.Colors.surfaceTop)
                        )
                        .foregroundColor(AppStyle.Colors.primary)
                        .font(AppStyle.Typography.headline())
                    }
                    .padding(.top, 8)
                }
                .padding(AppStyle.Layout.cardPadding)
            }
            .background(AppStyle.Colors.background.edgesIgnoringSafeArea(.all))
            .navigationTitle("Movement Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppStyle.Colors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showingMovementPicker) {
                // Present the movement picker with filtering by the primary muscles
                // This allows the user to find similar movements that target the same muscles
                MovementPickerView(filterByMuscles: movement.primaryMuscles) { selectedMovements in
                    if let replacement = selectedMovements.first, let callback = onReplaceMovement {
                        callback(replacement)
                        dismiss() // Dismiss the entire sheet after replacement
                    }
                }
            }
        }
    }
}
