import Foundation

@available(iOS, deprecated: 16)
@available(tvOS, deprecated: 16)
@available(macOS, deprecated: 13)
@available(watchOS, deprecated: 9)
extension Backport<Any> {
    /// The visibility levels that specify the kinds of apps and processes
    /// that can see an item in transit.
    public struct TransferRepresentationVisibility: Sendable, Equatable {
        enum Visibility {
            @available(iOS, unavailable)
            @available(tvOS, unavailable)
            @available(watchOS, unavailable)
            case group
            case ownProcess
            case all
        }

        let visibility: Visibility

        /// The visibility level that specifies that any app or process can access the item.
        public static let all: Self = .init(visibility: .all)

        /// The visibility level that specifies that the item is visible only
        /// to macOS apps in the same App Group.
        @available(iOS, unavailable)
        @available(tvOS, unavailable)
        @available(watchOS, unavailable)
        public static let group: Self = .init(visibility: .group)

        /// The visibility level that specifies that the item is visible only
        /// within the app that's the source of the item.
        public static let ownProcess: Self = .init(visibility: .ownProcess)
    }
}
