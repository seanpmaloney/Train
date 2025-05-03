# Train App Models

This directory contains the core domain models and business logic of the Train app. The model layer implements a clean architecture that separates data structures from business logic.

## Entity Structure

### Core Entities

The app follows a hierarchical structure for workout planning:

```
TrainingPlanEntity
└── WorkoutEntity
    └── ExerciseInstanceEntity
        └── ExerciseSetEntity
            └── (Performance data: weight, reps, etc.)
```

- **TrainingPlanEntity**: Represents an entire training program spanning multiple weeks
- **WorkoutEntity**: A single training session within a plan
- **ExerciseInstanceEntity**: A specific exercise performed in a workout
- **ExerciseSetEntity**: A single set of an exercise with weight and rep targets

### Supporting Entities

- **MovementEntity**: Template for an exercise describing targeted muscles and equipment
- **MuscleGroup**: Enum of all muscle groups with evidence-based training guidelines
- **MuscleTrainingPreference**: Links a muscle group with a specific training goal
- **EquipmentType**: Available exercise equipment options

## Plan Generation Components

The app uses a sophisticated system to generate personalized training plans:

- **PlanGenerator**: Creates training plans based on user preferences
- **VolumeRampStrategy**: Implements progressive volume increases across a plan
- **WorkoutBuilder**: Creates balanced workouts with appropriate exercises
- **ExerciseSelector**: Selects exercises that target specified muscles

## User Input Data Collected in the Questionnaire

The adaptive plan questionnaire collects the following user inputs to generate a personalized training plan:

### 1. Training Goal
- **Options**: Hypertrophy ("Build Muscle") or Strength ("Get Stronger")
- **Impact**: Determines rep ranges, intensity levels, and training volume
- **Default**: None, required input
- **Implementation**: `TrainingGoal` enum in AdaptivePlanModels.swift

### 2. Prioritized Muscle Groups
- **Options**: Multiple selection from all major muscle groups (chest, back, quads, hamstrings, etc.)
- **Impact**: Creates `MuscleTrainingPreference` objects with appropriate goals (.grow for selected, .maintain for others)
- **Default**: Empty set, but can proceed with none selected (all muscles set to maintenance)
- **Implementation**: `priorityMuscles` as a `Set<MuscleGroup>` in PlanPreferences

### 3. Training Frequency
- **Options**: 2, 3, 4, 5, or 6 days per week
- **Impact**: Determines weekly workout scheduling and volume distribution
- **Default**: None, required input
- **Implementation**: `DaysPerWeek` enum with descriptions like "Balanced approach" (3 days) or "All-in" (6 days)

### 4. Workout Duration
- **Options**: Short (~30 minutes), Medium (~45 minutes), Long (~60+ minutes)
- **Impact**: Influences number of exercises per workout (4 for short, 6 for medium, 8 for long)
- **Default**: None, required input
- **Implementation**: `WorkoutDuration` enum with descriptive flavor text

### 5. Available Equipment
- **Options**: Multiple selection from Barbell, Dumbbell, Machine, Bodyweight, Cable
- **Impact**: Filters exercise selection to match available equipment
- **Default**: Empty set, but at least one selection required
- **Implementation**: `availableEquipment` as a `Set<EquipmentType>` in PlanPreferences

### 6. Training Split Style
- **Options**: Full Body, Upper/Lower, Push/Pull/Legs
- **Impact**: Determines workout day types and muscle grouping strategy
- **Default**: None, required input
- **Implementation**: `SplitStyle` enum with descriptions of each approach

### 7. Training Experience Level
- **Options**: Beginner, Intermediate, Advanced
- **Impact**: Adjusts volume, intensity, and exercise selection for safety and effectiveness:
  - Beginners: 70% of standard volume, higher rep ranges for technique learning
  - Intermediates: 90% of standard volume, moderate rep ranges
  - Advanced: 100% of standard volume, full flexibility in rep ranges
- **Default**: None, required input
- **Implementation**: `TrainingExperience` enum with numeric `trainingAge` mapping

### Data Flow Process

1. All preferences are collected in a `PlanPreferences` struct as the user progresses through the questionnaire
2. The `isComplete` computed property verifies all required fields are populated
3. Data is converted to a `PlanInput` model via the `fromPreferences` method
4. The `PlanGenerator` uses this input to create a personalized `TrainingPlanEntity`
5. Training volumes are calculated based on muscle guidelines and adjusted by experience level
6. Workout structures are determined by split style and available equipment
7. Exercise selection prioritizes compound movements that efficiently target specified muscles

## File Descriptions

| File | Description |
|------|-------------|
| AdaptivePlanModels.swift | Models for personalized plan questionnaire (goals, experience, etc.) |
| ExerciseInstance.swift | Represents a specific exercise within a workout |
| ExerciseSet.swift | Manages individual sets with weight, reps, and completion status |
| Goals.swift | Defines training goals (growth, maintenance, etc.) |
| MockTrainingData.swift | Provides sample data for testing and development |
| MovementEntity.swift | Defines exercise movements with muscle targeting information |
| MovementLibrary.swift | Collection of exercise movements available in the app |
| MovementType.swift | Categorizes movement patterns (push, pull, etc.) |
| MuscleGroup.swift | Defines muscle groups with evidence-based training guidelines |
| PersistenceController.swift | Manages data persistence using Core Data |
| PlanGenerator.swift | Creates personalized training plans based on user input |
| PlanTemplate.swift | Templates for common training plan structures |
| TrainingDataRoot.swift | Root structure for app's training data |
| TrainingDataStore.swift | Manages access to training data |
| TrainingPlan.swift | Core entity representing a complete training program |
| TrainingPlanBuilder.swift | Helper for constructing training plans step by step |
| TrainingSession.swift | Records training session progress and metrics |
| TrainingType.swift | Categorizes training modalities |
| VolumeRampStrategy.swift | Implements progressive volume increases across a plan |
| Workout.swift | Represents a single workout session |
| WorkoutDay.swift | Defines workout template for a specific day of the week |

## Key Features

1. **Evidence-Based Training**: Volume recommendations based on scientific literature
2. **Progressive Overload**: Smart volume progression based on training experience
3. **Flexible Planning**: Support for various training splits and equipment options
4. **Personalization**: Adapts to user goals, preferences, and equipment availability

## Implementation Notes

- All entities conform to `Codable` for serialization
- Core entities conform to `ObservableObject` for SwiftUI binding
- Repository pattern used for data access
- Strategy pattern used for plan generation components
