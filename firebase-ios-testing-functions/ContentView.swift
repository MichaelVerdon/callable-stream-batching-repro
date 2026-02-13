import SwiftUI

struct ContentView: View {
    @StateObject var firebaseManager = FirebaseManager()
    @State private var chunks: [String] = []
    @State private var isStreaming = false

    // Timestamp helper
    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 20) {
            Button(isStreaming ? "Streaming..." : "Call Tiny Chunk Stream") {
                startTinyChunkStream()
            }
            .disabled(isStreaming)
            .padding()
            .buttonStyle(.borderedProminent)

            List(chunks, id: \.self) { chunk in
                Text(chunk)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding()
    }

    private func startTinyChunkStream() {
        chunks = []
        isStreaming = true

        Task {
            let params: [String: Any] = ["count": 5, "delay": 500] // adjust as needed

            await firebaseManager.callStreamingFunction(
                functionName: "tinyChunkStream",
                parameters: params,
                onChunk: { chunk in
                    let log = "\(timestamp()) \(chunk)"
                    chunks.append(log)
                },
                simulatedDelay: 200_000_000 // 0.2s per chunk to visualize streaming
            )

            isStreaming = false
        }
    }
}

#Preview {
    ContentView()
}
