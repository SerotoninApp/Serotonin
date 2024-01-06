import Foundation

@available(iOS, deprecated: 16)
@available(tvOS, deprecated: 16)
@available(macOS, deprecated: 13)
@available(watchOS, deprecated: 9)
public extension Backport<Any> {
    struct ReceivedTransferredFile : Sendable {

        /// The received file on disk.
        public let file: URL

        /// A Boolean value that indicates whether the file's URL
        /// points to the original file provided by the sender
        /// or to a copy.
        public let isOriginalFile: Bool
    }
}
