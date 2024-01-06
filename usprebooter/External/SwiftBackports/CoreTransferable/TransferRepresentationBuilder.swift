import Foundation
import Combine

@available(iOS, deprecated: 16)
@available(tvOS, deprecated: 16)
@available(macOS, deprecated: 13)
@available(watchOS, deprecated: 9)
public extension Backport<Any> {
    /// Creates a transfer representation by composing existing transfer representations.
    @resultBuilder
    struct TransferRepresentationBuilder<Item> where Item: BackportTransferable {
//        /// Builds an encodable and decodable transfer representation from an expression.
//        public static func buildExpression<Encoder, Decoder>(_ content: Backport.CodableRepresentation<Item, Encoder, Decoder>) -> Backport.CodableRepresentation<Item, Encoder, Decoder> where Item: Decodable, Item: Encodable, Encoder: TopLevelEncoder, Decoder: TopLevelDecoder, Encoder.Output == Data, Decoder.Input == Data {
//            Backport.CodableRepresentation(for: Item.self, contentType: Item)
//        }
//
//        /// Builds a transfer representation from an expression.
//        public static func buildExpression<R>(_ content: R) -> R where Item == R.Item, R: BackportTransferRepresentation {
//            fatalError()
//        }

        /// Passes a single transfer representation to the builder unmodified.
        public static func buildBlock<Content>(_ content: Content) -> Content where Item == Content.Item, Content: BackportTransferRepresentation {
            fatalError()
        }

//        /// Combines multiple transfer representations into a single transfer representation.
//        public static func buildBlock<C1, C2>(_ content1: C1, _ content2: C2) -> Backport.TupleTransferRepresentation<Item, (C1, C2)> where Item == C1.Item, C1: BackportTransferRepresentation, C2: BackportTransferRepresentation, C1.Item == C2.Item {
//            fatalError()
//        }
//
//        /// Combines multiple transfer representations into a single transfer representation.
//        public static func buildBlock<C1, C2, C3>(_ content1: C1, _ content2: C2, _ content3: C3) -> Backport.TupleTransferRepresentation<Item, (C1, C2, C3)> where Item == C1.Item, C1: BackportTransferRepresentation, C2: BackportTransferRepresentation, C3: BackportTransferRepresentation, C1.Item == C2.Item, C2.Item == C3.Item {
//            fatalError()
//        }
//
//        /// Combines multiple transfer representations into a single transfer representation.
//        public static func buildBlock<C1, C2, C3, C4>(_ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4) -> Backport.TupleTransferRepresentation<Item, (C1, C2, C3, C4)> where Item == C1.Item, C1: BackportTransferRepresentation, C2: BackportTransferRepresentation, C3: BackportTransferRepresentation, C4: BackportTransferRepresentation, C1.Item == C2.Item, C2.Item == C3.Item, C3.Item == C4.Item {
//            fatalError()
//        }
//
//        /// Combines multiple transfer representations into a single transfer representation.
//        public static func buildBlock<C1, C2, C3, C4, C5>(_ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4, _ content5: C5) -> Backport.TupleTransferRepresentation<Item, (C1, C2, C3, C4, C5)> where Item == C1.Item, C1: BackportTransferRepresentation, C2: BackportTransferRepresentation, C3: BackportTransferRepresentation, C4: BackportTransferRepresentation, C5: BackportTransferRepresentation, C1.Item == C2.Item, C2.Item == C3.Item, C3.Item == C4.Item, C4.Item == C5.Item {
//            fatalError()
//        }
//
//        /// Combines multiple transfer representations into a single transfer representation.
//        public static func buildBlock<C1, C2, C3, C4, C5, C6>(_ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4, _ content5: C5, _ content6: C6) -> Backport.TupleTransferRepresentation<Item, (C1, C2, C3, C4, C5, C6)> where Item == C1.Item, C1: BackportTransferRepresentation, C2: BackportTransferRepresentation, C3: BackportTransferRepresentation, C4: BackportTransferRepresentation, C5: BackportTransferRepresentation, C6: BackportTransferRepresentation, C1.Item == C2.Item, C2.Item == C3.Item, C3.Item == C4.Item, C4.Item == C5.Item, C5.Item == C6.Item {
//            fatalError()
//        }
//
//        /// Combines multiple transfer representations into a single transfer representation.
//        public static func buildBlock<C1, C2, C3, C4, C5, C6, C7>(_ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4, _ content5: C5, _ content6: C6, _ content7: C7) -> Backport.TupleTransferRepresentation<Item, (C1, C2, C3, C4, C5, C6, C7)> where Item == C1.Item, C1: BackportTransferRepresentation, C2: BackportTransferRepresentation, C3: BackportTransferRepresentation, C4: BackportTransferRepresentation, C5: BackportTransferRepresentation, C6: BackportTransferRepresentation, C7: BackportTransferRepresentation, C1.Item == C2.Item, C2.Item == C3.Item, C3.Item == C4.Item, C4.Item == C5.Item, C5.Item == C6.Item, C6.Item == C7.Item {
//            fatalError()
//        }
//
//        /// Combines multiple transfer representations into a single transfer representation.
//        public static func buildBlock<C1, C2, C3, C4, C5, C6, C7, C8>(_ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4, _ content5: C5, _ content6: C6, _ content7: C7, _ content8: C8) -> Backport.TupleTransferRepresentation<Item, (C1, C2, C3, C4, C5, C6, C7, C8)> where Item == C1.Item, C1: BackportTransferRepresentation, C2: BackportTransferRepresentation, C3: BackportTransferRepresentation, C4: BackportTransferRepresentation, C5: BackportTransferRepresentation, C6: BackportTransferRepresentation, C7: BackportTransferRepresentation, C8: BackportTransferRepresentation, C1.Item == C2.Item, C2.Item == C3.Item, C3.Item == C4.Item, C4.Item == C5.Item, C5.Item == C6.Item, C6.Item == C7.Item, C7.Item == C8.Item {
//            fatalError()
//        }
//
//        /// Combines multiple transfer representations into a single transfer representation.
//        public static func buildBlock<C1, C2, C3, C4, C5, C6, C7, C8, C9>(_ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4, _ content5: C5, _ content6: C6, _ content7: C7, _ content8: C8, _ content9: C9) -> Backport.TupleTransferRepresentation<Item, (C1, C2, C3, C4, C5, C6, C7, C8, C9)> where Item == C1.Item, C1: BackportTransferRepresentation, C2: BackportTransferRepresentation, C3: BackportTransferRepresentation, C4: BackportTransferRepresentation, C5: BackportTransferRepresentation, C6: BackportTransferRepresentation, C7: BackportTransferRepresentation, C8: BackportTransferRepresentation, C9: BackportTransferRepresentation, C1.Item == C2.Item, C2.Item == C3.Item, C3.Item == C4.Item, C4.Item == C5.Item, C5.Item == C6.Item, C6.Item == C7.Item, C7.Item == C8.Item, C8.Item == C9.Item {
//            fatalError()
//        }
//
//        /// Combines multiple transfer representations into a single transfer representation.
//        public static func buildBlock<C1, C2, C3, C4, C5, C6, C7, C8, C9, C10>(_ content1: C1, _ content2: C2, _ content3: C3, _ content4: C4, _ content5: C5, _ content6: C6, _ content7: C7, _ content8: C8, _ content9: C9, _ content10: C10) -> Backport.TupleTransferRepresentation<Item, (C1, C2, C3, C4, C5, C6, C7, C8, C9, C10)> where Item == C1.Item, C1: BackportTransferRepresentation, C2: BackportTransferRepresentation, C3: BackportTransferRepresentation, C4: BackportTransferRepresentation, C5: BackportTransferRepresentation, C6: BackportTransferRepresentation, C7: BackportTransferRepresentation, C8: BackportTransferRepresentation, C9: BackportTransferRepresentation, C10: BackportTransferRepresentation, C1.Item == C2.Item, C2.Item == C3.Item, C3.Item == C4.Item, C4.Item == C5.Item, C5.Item == C6.Item, C6.Item == C7.Item, C7.Item == C8.Item, C8.Item == C9.Item, C9.Item == C10.Item {
//            fatalError()
//        }
    }
}
