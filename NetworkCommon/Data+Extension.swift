import Foundation

extension Data {
    static let end = Data("\r\n".utf8)

    func hasSuffix(_ data: Data) -> Bool {
        let suff = self.suffix(Self.end.count)
        return suff == Self.end
    }
}
