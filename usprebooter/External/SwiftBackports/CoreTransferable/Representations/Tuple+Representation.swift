//import Foundation
//
//@available(iOS, deprecated: 16)
//@available(tvOS, deprecated: 16)
//@available(macOS, deprecated: 13)
//@available(watchOS, deprecated: 9)
//public extension Backport<Any> {
//    /// A wrapper type for tuples that contain transfer representations.
//    struct TupleTransferRepresentation<Item, Value>: BackportTransferRepresentation where Item: BackportTransferable, Value: Sendable {
//        /// A builder expression that describes the process of importing and exporting an item.
//        ///
//        /// Combine multiple existing transfer representations
//        /// to compose a single transfer representation that describes
//        /// how to transfer an item in multiple scenarios.
//        ///
//        ///     struct CombinedRepresentation: BackportTransferRepresentation {
//        ///        var body: some BackportTransferRepresentation {
//        ///            Backport.DataRepresentation(...)
//        ///            Backport.FileRepresentation(...)
//        ///        }
//        ///     }
//        ///
//        public var body: some BackportTransferRepresentation {
//            fatalError()
//        }
//    }
//}
