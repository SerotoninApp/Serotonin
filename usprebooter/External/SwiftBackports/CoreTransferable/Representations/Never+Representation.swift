import Foundation

extension Never: BackportTransferRepresentation {
    /// The type of the item that's being transferred.
    public typealias Item = Never

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
    public var body: Never { fatalError() }
}
