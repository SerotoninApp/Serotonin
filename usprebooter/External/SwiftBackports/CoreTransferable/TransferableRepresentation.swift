import Foundation

/// A declarative description of the process of importing and exporting a transferable item.
///
/// Combine multiple existing transfer representations
/// to compose a single transfer representation that describes
/// how to transfer an item in multiple scenarios.
///
/// The following shows a `Greeting` type that transfers both as a `Codable` type
/// and by proxy through its `message` string.
///
///     import UniformTypeIdentifiers
///
///     struct Greeting: Codable, BackportTransferable {
///         let message: String
///         var displayInAllCaps: Bool = false
///
///         static var transferRepresentation: some BackportTransferRepresentation {
///             Backport.CodableRepresentation(contentType: .greeting)
///             Backport.ProxyRepresentation(exporting: \.message)
///         }
///     }
///
///     extension Backport.UTType {
///         static var greeting: Backport.UTType { .init(exportedAs: "com.example.greeting") }
///     }
///
@available(iOS, deprecated: 16)
@available(tvOS, deprecated: 16)
@available(macOS, deprecated: 13)
@available(watchOS, deprecated: 9)
public protocol BackportTransferRepresentation<Item>: Sendable {
    /// The type of the item that's being transferred.
    associatedtype Item: BackportTransferable

    /// The transfer representation for the item.
    associatedtype Body: BackportTransferRepresentation

    /// A builder expression that describes the process of importing and exporting an item.
    ///
    /// Combine multiple existing transfer representations
    /// to compose a single transfer representation that describes
    /// how to transfer an item in multiple scenarios.
    ///
    ///     struct CombinedRepresentation: BackportTransferRepresentation {
    ///        var body: some BackportTransferRepresentation {
    ///            Backport.DataRepresentation(...)
    ///            Backport.FileRepresentation(...)
    ///        }
    ///     }
    ///
    @Backport<Any>.TransferRepresentationBuilder<Item> var body: Body { get }
}

//extension BackportTransferRepresentation {
//    /// Specifies the kinds of apps and processes that can see an item in transit.
//    ///
//    /// - Parameters:
//    ///   - visibility: The visibility level.
//    public func visibility(_ visibility: Backport<Any>.TransferRepresentationVisibility) -> some BackportTransferRepresentation {
//        fatalError()
//    }
//}
//
//extension BackportTransferRepresentation {
//
//    /// Prevents the system from exporting an item if it does not meet the supplied condition.
//    ///
//    /// Some instances of a model type may have state-dependent conditions that make them
//    /// unsuitable for export. For example, an `Archive` structure that supports
//    /// a comma-separated text representation only when it has compatible content:
//    ///
//    ///     struct Archive {
//    ///         var supportsCSV: Bool
//    ///         func csvData() -> Data
//    ///         init(csvData: Data)
//    ///     }
//    ///
//    ///     extension Archive: BackportTransferable {
//    ///         static var transferRepresentation: some BackportTransferRepresentation {
//    ///             Backport.DataRepresentation(contentType: .commaSeparatedText) { archive in
//    ///                 archive.csvData()
//    ///             } importing: { data in Archive(csvData: data) }
//    ///                 .exportingCondition { archive in archive.supportsCSV }
//    ///         }
//    ///     }
//    ///
//    /// - Parameters:
//    ///   - condition: A closure that determines whether the item is exportable.
//    public func exportingCondition(_ condition: @escaping @Sendable (Item) -> Bool) -> Backport<Any>._ConditionalTransferRepresentation<Self> {
//        Backport<Any>._ConditionalTransferRepresentation<Self>(condition: condition)
//    }
//}
//
//extension BackportTransferRepresentation {
//    /// Provides a filename to use if the receiver chooses to write the item to disk.
//    ///
//    /// Any transfer representation can be written to disk.
//    ///
//    ///      extension ImageDocumentLayer: BackportTransferable {
//    ///          static var transferRepresentation: some BackportTransferRepresentation {
//    ///              Backport.DataRepresentation(contentType: .layer) { layer in
//    ///                  layer.data()
//    ///                  } importing: { data in
//    ///                      try ImageDocumentLayer(data: data)
//    ///                  }
//    ///                  .suggestedFileName("Layer.exampleLayer")
//    ///              Backport.DataRepresentation(exportedContentType: .png) { layer in
//    ///                  layer.pngData()
//    ///              }
//    ///              .suggestedFileName("Layer.png")
//    ///          }
//    ///      }
//    ///
//    /// The .exampleLayer filename extension above should match
//    /// the extension for the `layer` content type,
//    /// which you declare in your app's `Info.plist` file.
//    ///
//    /// - Parameters:
//    ///   - fileName: The suggested filename including the filename extension.
//    public func suggestedFileName(_ fileName: String) -> some BackportTransferRepresentation {
//        fatalError()
//    }
//}
