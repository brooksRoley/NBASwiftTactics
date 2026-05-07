import SwiftUI
import Combine
#if canImport(UIKit)
import UIKit
#endif

struct CourtMarker: Identifiable, Hashable {
    let id: UUID = UUID()
    var position: CGPoint
    var label: String
}

final class CourtState: ObservableObject {
    @Published var markers: [CourtMarker] = []
    @Published var paths: [[CGPoint]] = []

    private var nextIndex: Int = 1

    func addMarker(at point: CGPoint) {
        let marker = CourtMarker(position: point, label: "P\(nextIndex)")
        nextIndex += 1
        markers.append(marker)
    }

    func updateMarker(_ marker: CourtMarker, to point: CGPoint) {
        if let idx = markers.firstIndex(of: marker) {
            markers[idx].position = point
        }
    }

    func startPath(at point: CGPoint) {
        paths.append([point])
    }

    func appendToCurrentPath(_ point: CGPoint) {
        guard !paths.isEmpty else { return }
        paths[paths.count - 1].append(point)
    }

    func clear() {
        markers.removeAll()
        paths.removeAll()
        nextIndex = 1
    }
}

struct BasketballCourtView: View {
    @StateObject private var state = CourtState()
    @State private var drawing = false

    var body: some View {
        GeometryReader { geo in
            let courtSize = CGSize(width: geo.size.width, height: geo.size.width / 1.88)
            VStack {
                Spacer(minLength: 0)
                ZStack {
                    PremiumCourtBackground(isHalfCourt: false)

                    // Drawn paths
                    ForEach(Array(state.paths.enumerated()), id: \.offset) { _, pathPoints in
                        Path { path in
                            guard let first = pathPoints.first else { return }
                            path.move(to: first)
                            for p in pathPoints.dropFirst() { path.addLine(to: p) }
                        }
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }

                    // Markers
                    ForEach(state.markers) { marker in
                        markerView(marker)
                            .position(marker.position)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let clamped = clamp(value.location, in: courtSize)
                                        state.updateMarker(marker, to: clamped)
                                    }
                            )
                    }
                }
                .frame(width: geo.size.width, height: courtSize.height)
                .background(Color.clear)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let point = clamp(value.location, in: courtSize)
                        if !drawing {
                            drawing = true
                            state.startPath(at: point)
                        } else {
                            state.appendToCurrentPath(point)
                        }
                    }
                    .onEnded { _ in drawing = false }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        // add marker at center of view tap location
                        // Using a dummy center because TapGesture lacks location; overlay a transparent drag to capture
                    }
            )
            .background {
                TouchCaptureView(onTap: { location in
                    let clamped = clamp(location, in: courtSize)
                    state.addMarker(at: clamped)
                })
            }
            .onReceive(NotificationCenter.default.publisher(for: .clearCourt)) { _ in
                state.clear()
            }
        }
    }

    // MARK: - Court Drawing Delegate (Removed, using PremiumCourtBackground)

    @ViewBuilder
    private func markerView(_ marker: CourtMarker) -> some View {
        ZStack {
            Circle().fill(Color.yellow).frame(width: 36, height: 36).shadow(radius: 2)
            Text(marker.label).font(.caption).bold().foregroundStyle(.black)
        }
        .accessibilityLabel(Text("Marker \(marker.label)"))
    }

    private func clamp(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: min(max(0, point.x), size.width), y: min(max(0, point.y), size.height))
    }
}

// MARK: - Touch capture for tap locations

#if canImport(UIKit)
private struct TouchCaptureView: UIViewRepresentable {
    var onTap: (CGPoint) -> Void

    func makeUIView(context: Context) -> TouchCaptureUIView {
        let v = TouchCaptureUIView(frame: .zero)
        v.onTap = onTap
        v.backgroundColor = .clear
        return v
    }

    func updateUIView(_ uiView: TouchCaptureUIView, context: Context) {
        uiView.onTap = onTap
    }
}

private final class TouchCaptureUIView: UIView {
    var onTap: ((CGPoint) -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: self)
        onTap?(point)
    }
}
#else
// Fallback touch capture for platforms without UIKit (e.g., macOS)
private struct TouchCaptureView: View {
    var onTap: (CGPoint) -> Void

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    TapGesture()
                        .onEnded {
                            // Use the center of the view as an approximation since TapGesture lacks location
                            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                            onTap(center)
                        }
                )
        }
    }
}
#endif

#Preview {
    BasketballCourtView()
}
