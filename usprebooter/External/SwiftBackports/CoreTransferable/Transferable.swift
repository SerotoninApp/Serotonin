import Foundation

/// A protocol that describes how a type interacts with transport APIs
/// such as drag and drop or copy and paste.
///
/// To conform to the `BackportTransferable` protocol,
/// implement the ``transferRepresentation`` property.
/// For example, an image editing app's layer type might
/// conform to `BackportTransferable` to let people drag and drop image layers
/// to reorder them within a document.
///
///     struct ImageDocumentLayer {
///         init(data: Data)
///         func data() -> Data
///         func pngData() -> Data
///     }
///
/// The following shows how you can extend `ImageDocumentLayer`  to
/// conform to `BackportTransferable`:
///
///     extension ImageDocumentLayer: BackportTransferable {
///         static var transferRepresentation: some BackportTransferRepresentation {
///             Backport.DataRepresentation(contentType: .layer) { layer in
///                     layer.data()
///                 }, importing: { data in
///                     try Layer(data: data)
///                 }
///             Backport.DataRepresentation(exportedContentType: .png) { layer in
///                 layer.pngData()
///         }
///     }
///
/// When people drag and drop a layer within the app or onto another app
/// that recognizes the custom `layer` content type,
/// the app uses the first representation.
/// When people drag and drop the layer onto a different image editor,
/// it's likely that the editor recognizes the PNG file type.
/// The second transfer representation adds support for PNG files.
///
/// The following declares the custom `layer` uniform type identifier:
///
///     extension Backport.UTType {
///         static var layer: Backport.UTType { Backport.UTType(exportedAs: "com.example.layer") }
///     }
///
/// > Important: If your app declares custom uniform type identifiers,
/// include corresponding entries in the app's `Info.plist`.
///
/// If one of your existing types conforms to `Codable`,
/// `BackportTransferable` automatically handles conversion to and from `Data`.
/// The following declares a simple `Note` structure that's `Codable`
/// and an extension to make it `BackportTransferable`:
///
///     struct Note: Codable {
///         let title: String
///         let body: String
///     }
///
///     extension Note: BackportTransferable {
///         static var transferRepresentation: some BackportTransferRepresentation {
///             Backport.CodableRepresentation(contentType: .note)
///         }
///     }
///
/// To ensure compatibility with other apps that don't know about
/// the custom `note` type identifier,
/// the following adds an additional transfer representation
/// that converts the note to text.
///
///     extension Note: BackportTransferable {
///         static var transferRepresentation: some BackportTransferRepresentation {
///             Backport.CodableRepresentation(contentType: .note)
///             Backport.ProxyRepresentation(\.title)
///         }
///     }
/// The order of the representations in the transfer representation matters;
/// place the representation that most accurately represents your type first,
/// followed by a sequence of more compatible
/// but less preferable representations.
///
@available(iOS, deprecated: 16)
@available(tvOS, deprecated: 16)
@available(macOS, deprecated: 13)
@available(watchOS, deprecated: 9)
public protocol BackportTransferable {

    /// The type of the representation used to import and export the item.
    ///
    /// Swift infers this type from the return value of the
    /// ``transferRepresentation`` property.
    associatedtype Representation: BackportTransferRepresentation

    /// The representation used to import and export the item.
    ///
    /// A ``transferRepresentation`` can contain multiple representations
    /// for different content types.
    @Backport<Any>.TransferRepresentationBuilder<Self> static var transferRepresentation: Representation { get }
}
