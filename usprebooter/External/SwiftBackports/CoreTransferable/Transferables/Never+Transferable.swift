import Foundation

@available(iOS, deprecated: 16)
@available(tvOS, deprecated: 16)
@available(macOS, deprecated: 13)
@available(watchOS, deprecated: 9)
extension Never: BackportTransferable {
    /// The representation used to import and export the item.
    ///
    /// A ``transferRepresentation`` can contain multiple representations
    /// for different content types.
    public static var transferRepresentation: Never { fatalError() }
}
