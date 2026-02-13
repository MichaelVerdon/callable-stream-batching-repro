import Foundation
import FirebaseCore
import FirebaseFunctions

@MainActor
class FirebaseManager: ObservableObject {
    lazy var functions: Functions = {
        guard FirebaseApp.app() != nil else {
            fatalError("FirebaseApp is not configured")
        }
        let f = Functions.functions(region: "us-central1")
#if DEBUG
        f.useEmulator(withHost: "127.0.0.1", port: 5001)
#endif
        return f
    }()

    public struct AnyEncodable: Encodable {
        private let value: Any?

        public init(_ value: Any?) {
            self.value = value ?? NSNull()
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch value {
            case is NSNull: try container.encodeNil()
            case let v as String: try container.encode(v)
            case let v as Int: try container.encode(v)
            case let v as Double: try container.encode(v)
            case let v as Bool: try container.encode(v)
            case let v as [Any]: try container.encode(v.map { AnyEncodable($0) })
            case let v as [String: Any]: try container.encode(v.mapValues { AnyEncodable($0) })
            default:
                throw EncodingError.invalidValue(
                    value as Any,
                    EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type")
                )
            }
        }
    }

    public struct AnyDecodable: Decodable {
        public let value: Any?

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                value = NSNull(); return
            }
            if let v = try? container.decode(String.self) { value = v }
            else if let v = try? container.decode(Int.self) { value = v }
            else if let v = try? container.decode(Double.self) { value = v }
            else if let v = try? container.decode(Bool.self) { value = v }
            else if let v = try? container.decode([AnyDecodable].self) { value = v.map(\.value) }
            else if let v = try? container.decode([String: AnyDecodable].self) { value = v.mapValues { $0.value } }
            else { value = nil }
        }

        public init(_ value: Any?) {
            self.value = value
        }
    }

    // MARK: - Helper to stringify any value for display
    private func stringify(_ value: Any?) -> String {
        guard let value = value else { return "nil" }

        if let str = value as? String {
            return str
        }
        if let num = value as? NSNumber {
            return num.stringValue
        }
        if JSONSerialization.isValidJSONObject(value) {
            if let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted]),
               let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            }
        }
        return "\(value)"
    }

    // MARK: - Streaming function
    func callStreamingFunction(
        functionName: String,
        parameters: [String: Any],
        onChunk: @escaping (String) -> Void,
        simulatedDelay: UInt64 = 0
    ) async {
        let callable: Callable<AnyEncodable, StreamResponse<AnyDecodable, AnyDecodable>> =
            functions.httpsCallable(functionName)

        do {
            let request = AnyEncodable(parameters)
            let stream = try callable.stream(request)

            for try await response in stream {
                switch response {
                case .message(let message):
                    let chunk = stringify(message.value)
                    await MainActor.run { onChunk(chunk) }
                    if simulatedDelay > 0 {
                        try? await Task.sleep(nanoseconds: simulatedDelay)
                    }
                case .result(let result):
                    let final = stringify(result.value)
                    await MainActor.run { onChunk("✅ Final: \(final)") }
                }
            }
        } catch {
            await MainActor.run {
                onChunk("❌ Error: \(error.localizedDescription)")
            }
        }
    }
}
