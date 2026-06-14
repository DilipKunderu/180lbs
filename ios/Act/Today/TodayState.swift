/// Every `Cmd*` node from the design.v5 Today-coordinator `stateDiagram-v2`.
/// Only `.weighIn` has a built renderer this milestone; all others map to a
/// "not yet built" placeholder in `TodayCoordinatorView`.
enum TodayState: CaseIterable, Equatable {
    case preWake
    case weighIn
    case preWorkout
    case workout
    case swim
    case fasting
    case hydration
    case reheat
    case eat
    case walk
    case eod
    case sleep
}
