import Foundation

extension Data {
    /// Decodes as UTF-8, replacing invalid bytes instead of failing.
    var lossyUTF8: String {
        // swiftlint:disable:next optional_data_string_conversion
        String(decoding: self, as: UTF8.self)
    }
}
