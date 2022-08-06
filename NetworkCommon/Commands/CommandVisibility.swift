import Foundation

public enum CommandVisibility {
    /// Must be handled with first priority
    case global
    /// Must be handled only in group
    case onlyGroup
    /// Commands that are acceptable only without active group handler
    case regular
}
