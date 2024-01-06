//import Foundation
//
//@available(iOS, deprecated: 16)
//@available(tvOS, deprecated: 16)
//@available(macOS, deprecated: 13)
//@available(watchOS, deprecated: 9)
//public extension Backport<Any> {
//    /// A transfer representation for types that transfer as a file URL.
//    ///
//    /// Use a `Backport.FileRepresentation` for transferring types
//    /// that involve a large amount of data.
//    /// For example, if your app defines a `Movie` type that could represent a lengthy video,
//    /// use a `Backport.FileRepresentation` instance
//    /// to transfer the video data to another app or process.
//    ///
//    ///     struct Movie: BackportTransferable {
//    ///         let url: URL
//    ///         static var transferRepresentation: some BackportTransferRepresentation {
//    ///             Backport.FileRepresentation(contentType: .mpeg4Movie) { movie in
//    ///                 Backport.SentTransferredFile($0.url)
//    ///                 } importing: { received in
//    ///                     let copy: URL = URL(fileURLWithPath: "<#...#>")
//    ///                     try FileManager.default.copyItem(at: received.file, to: copy)
//    ///                     return Self.init(url: copy) }
//    ///         }
//    ///     }
//    /// It's efficient to pass such data around as a file and the receiver
//    /// loads it into memory only if it's required.
//    ///
//    struct FileRepresentation<Item>: BackportTransferRepresentation where Item: BackportTransferable {
//        /// Creates a transfer representation for importing and exporting
//        /// transferable items as files.
//        ///
//        /// - Parameters:
//        ///   - contentType: A uniform type identifier that best describes the item.
//        ///   - shouldAttemptToOpenInPlace: A Boolean value that
//        ///   indicates whether the receiver gains access to the original item on disk
//        ///   and can edit it,
//        ///   or to a copy made by the system.
//        ///   - exporting: A closure that provides a file representation of the given item.
//        ///   - importing: A closure that instantiates the item with given file promise.
//        /// The file referred to by the
//        /// `Backport.ReceivedTransferredFile.file` property of the
//        /// `Backport.ReceivedTransferredFile` instance
//        /// is only guaranteed to exist within the `importing` closure. If you need the file
//        /// to be around for a longer period, make a copy in the `importing` closure.
//        public init(contentType: Backport.UTType, shouldAttemptToOpenInPlace: Bool = false, exporting: @escaping @Sendable (Item) async throws -> Backport.SentTransferredFile, importing: @escaping @Sendable (Backport.ReceivedTransferredFile) async throws -> Item) {
//
//        }
//
//        /// Creates a transfer representation for exporting transferable items as files.
//        ///
//        /// - Parameters:
//        ///   - exportedContentType: A uniform type identifier for the file `URL`,
//        ///   returned by the `exporting` closure.
//        ///   - shouldAllowToOpenInPlace: A Boolean value that indicates whether
//        ///   the receiver can try to gain access to the original item on disk
//        ///   and can edit it.
//        ///   If `false`, the receiver only has access to a copy of the file
//        ///   made by the system.
//        ///   - exporting: A closure that provides a file representation of the given item.
//        public init(exportedContentType: Backport.UTType, shouldAllowToOpenInPlace: Bool = false, exporting: @escaping @Sendable (Item) async throws -> Backport.SentTransferredFile) {
//
//        }
//
//        /// Creates a transfer representation for importing transferable items as files.
//        ///
//        /// - Parameters:
//        ///   - importedContentType: A uniform type identifier for the file promise,
//        ///   returned by the `exporting` closure.
//        ///   - shouldAttemptToOpenInPlace: A Boolean value that indicates whether
//        ///   the receiver wants to gain access to the original item on disk
//        ///   and can edit it.
//        ///   If `false`, the receiver only has access to a copy of the file
//        ///   made by the system.
//        ///   - importing: A closure that creates the item with given file promise.
//        /// The file referred to by the `file` property of the `ReceivedTransferredFile`
//        /// is only guaranteed to exist within the `importing` closure. If you need the file
//        /// to be around for a longer period, make a copy in the `importing` closure.
//        public init(importedContentType: Backport.UTType, shouldAttemptToOpenInPlace: Bool = false, importing: @escaping @Sendable (Backport.ReceivedTransferredFile) async throws -> Item) {
//
//        }
//
//        /// The transfer representation for the item.
//        public typealias Body = Never
//    }
//}
