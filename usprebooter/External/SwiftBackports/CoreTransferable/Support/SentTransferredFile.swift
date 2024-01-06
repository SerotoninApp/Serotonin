import Foundation

@available(iOS, deprecated: 16)
@available(tvOS, deprecated: 16)
@available(macOS, deprecated: 13)
@available(watchOS, deprecated: 9)
public extension Backport<Any> {
    struct SentTransferredFile: Sendable {

        /// A URL that describes the location of the file.
        public let file: URL

        /// A Boolean value that indicates whether
        /// the receiver can read and write the original file.
        /// When set to `false`, the receiver can only gain access to a copy of the file.
        public let allowAccessingOriginalFile: Bool

        /// Creates a description of a file from the perspective of the sender.
        ///
        /// - Parameters:
        ///   - file: A URL that describes the location of the file.
        ///   - allowAccessingOriginalFile: A Boolean value that indicates whether
        /// the receiver can read and write the original file.
        /// When set to `false`, the receiver can only gain access to a copy of the file.
        public init(_ file: URL, allowAccessingOriginalFile: Bool = false) {
            self.file = file
            self.allowAccessingOriginalFile = allowAccessingOriginalFile
        }
    }
}
