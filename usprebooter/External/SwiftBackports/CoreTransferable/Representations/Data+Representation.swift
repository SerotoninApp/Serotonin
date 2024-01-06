//import Foundation
//
//public extension Backport<Any> {
//    /// A transfer representation for types that provide their own binary data conversion.
//    ///
//    /// Use this transfer representation if your model is stored in memory.
//    /// For example, a drawing app might have a notion of a *layer*
//    /// that can be converted to and from a custom binary data format and
//    /// also converted to the PNG image type:
//    ///
//    ///     struct ImageDocumentLayer {
//    ///         init(data: Data) throws
//    ///         func data() -> Data
//    ///         func pngData() -> Data
//    ///     }
//    ///
//    /// You can provide multiple transfer representations for a model type,
//    /// even if the transfer representation types are the same.
//    /// The following shows the `ImageDocumentLayer` structure
//    /// conforming to `BackportTransferable` with two `Backport.DataRepresentation` instances
//    /// composed together:
//    ///
//    ///     extension ImageDocumentLayer: BackportTransferable {
//    ///         static var transferRepresentation: some BackportTransferRepresentation {
//    ///             Backport.DataRepresentation(contentType: .layer) { layer in
//    ///                     layer.data()
//    ///                 } importing: { data in
//    ///                     try ImageDocumentLayer(data: data)
//    ///                 }
//    ///             Backport.DataRepresentation(exportedContentType: .png) { layer in
//    ///                 layer.pngData()
//    ///             }
//    ///         }
//    ///     }
//    ///
//    /// The example drawing app's custom transfer representation comes first
//    /// so that apps that know about the custom transfer representation can use it.
//    /// The second transfer representation offers export compatibility with other apps
//    /// that work with PNG images.
//    ///
//    /// > Tip: If a type conforms to `Codable`, `Backport.CodableRepresentation` might be
//    /// a more convenient choice than `Backport.DataRepresentation`.
//    struct DataRepresentation<Item>: BackportTransferRepresentation where Item: BackportTransferable {
//        let representation: DataTransferRepresentation
//
//        /// Creates a representation that allows transporting an item as binary data.
//        ///
//        /// - Parameters:
//        ///   - contentType: A uniform type identifier that best describes the item.
//        ///   - exporting: A closure that provides a data representation of the given item.
//        ///   - importing: A closure that instantiates the item with given binary data.
//        public init(contentType: Backport.UTType, exporting: @escaping @Sendable (Item) async throws -> Data, importing: @escaping @Sendable (Data) async throws -> Item) {
//            representation = .init(contentType: contentType, exporting: exporting, importing: importing)
//        }
//
//        /// Creates a representation that allows exporting an item as binary data.
//        ///
//        /// - Parameters:
//        ///   - exportedContentType: A uniform type identifier that best describes the item.
//        ///   - exporting: A closure that provides a data representation of the given item.
//        public init(exportedContentType: Backport.UTType, exporting: @escaping @Sendable (Item) async throws -> Data) {
//            representation = .init(contentType: exportedContentType, exporting: exporting)
//        }
//
//        /// Creates a representation that allows importing an item as binary data.
//        ///
//        /// - Parameters:
//        ///   - importedContentType: A uniform type identifier that best describes the item.
//        ///   - importing: A closure that instantiates the item with given binary data
//        public init(importedContentType: Backport.UTType, importing: @escaping @Sendable (Data) async throws -> Item) {
//            representation = .init(contentType: importedContentType, importing: importing)
//        }
//
//        public var body: Never { fatalError() }
//    }
//
//}
//
//struct DataTransferRepresentation {
//    let contentType: Backport<Any>.UTType
//    let exporting: (@Sendable (Any) async throws -> Data)?
//    let importing: (@Sendable (Data) async throws -> Any)?
//
//    init<Item: BackportTransferable>(contentType: Backport<Any>.UTType, exporting: @escaping (Item) async throws -> Data, importing: @escaping (Data) async throws -> Item) {
//        self.contentType = contentType
//        self.exporting = { item in try await exporting(item as! Item) }
//        self.importing = { data in try await importing(data) }
//    }
//
//    init<Item: BackportTransferable>(contentType: Backport<Any>.UTType, exporting: @escaping (Item) async throws -> Data) {
//        self.contentType = contentType
//        self.exporting = { item in try await exporting(item as! Item) }
//    }
//
//    init<Item: BackportTransferable>(contentType: Backport<Any>.UTType, importing: @escaping (Data) async throws -> Item) {
//        self.contentType = contentType
//        self.importing = { data in try await importing(data) }
//    }
//}
