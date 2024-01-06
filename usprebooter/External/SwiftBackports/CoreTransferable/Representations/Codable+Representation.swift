//import Foundation
//import Combine
//
//@available(iOS, deprecated: 16)
//@available(tvOS, deprecated: 16)
//@available(macOS, deprecated: 13)
//@available(watchOS, deprecated: 9)
//public extension Backport<Any> {
//    /// A transfer representation for types that participate in Swift's protocols for encoding and decoding.
//    ///
//    ///     struct Todo: Codable, BackportTransferable {
//    ///         var text: String
//    ///         var isDone = false
//    ///
//    ///         static var transferRepresentation: some BackportTransferRepresentation {
//    ///             Backport.CodableRepresentation(contentType: .todo)
//    ///         }
//    ///     }
//    ///
//    ///      extension Backport.UTType {
//    ///          static var todo: Backport.UTType { .init(exportedAs: "com.example.todo") }
//    ///     }
//    ///
//    /// > Important: If your app declares custom uniform type identifiers,
//    /// include corresponding entries in the app's `Info.plist`.
//    ///
//    struct CodableRepresentation<Item, Encoder, Decoder>: BackportTransferRepresentation, Sendable where Item: BackportTransferable, Item: Decodable, Item: Encodable, Encoder: TopLevelEncoder, Decoder: TopLevelDecoder, Encoder.Output == Data, Decoder.Input == Data {
//        /// Creates a transfer representation for a given type and type identifier.
//        ///
//        /// This initializer uses JSON for encoding and decoding.
//        ///
//        /// - Parameters:
//        ///   - itemType: The concrete type of the item that's being transferred.
//        ///   - contentType: A uniform type identifier that best describes the item.
//        public init(for itemType: Item.Type = Item.self, contentType: Backport.UTType) where Encoder == JSONEncoder, Decoder == JSONDecoder {
//
//        }
//
//        /// Creates a transfer representation for a given type with the encoder and decoder you supply.
//        ///
//        /// - Parameters:
//        ///   - itemType: The concrete type of the item that's being transported.
//        ///   - contentType: A uniform type identifier that best describes the item.
//        ///   - encoder: An instance of a type that can convert the item being transferred
//        ///   into binary data with a specific structure.
//        ///   - decoder: An instance of a type that can convert specifically structured
//        ///   binary data into the item being transferred.
//        public init(for itemType: Item.Type = Item.self, contentType: Backport.UTType, encoder: Encoder, decoder: Decoder) {
//
//        }
//
//        /// The transfer representation for the item.
//        public typealias Body = Never
//    }
//}
