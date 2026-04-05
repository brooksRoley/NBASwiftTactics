import SwiftUI
#if canImport(Combine)
import Combine
#endif
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
            ZStack {
                court(in: geo.size)
                    .fill(Color.orange.opacity(0.15))
                    .overlay(courtLines(in: geo.size).stroke(Color.brown, lineWidth: 2))

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
                                    let clamped = clamp(value.location, in: geo.size)
                                    state.updateMarker(marker, to: clamped)
                                }
                        )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        let point = clamp(value.location, in: geo.size)
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
                    let clamped = clamp(location, in: geo.size)
                    state.addMarker(at: clamped)
                })
            }
            .onReceive(NotificationCenter.default.publisher(for: .clearCourt)) { _ in
                state.clear()
            }
        }
    }

    // MARK: - Court Drawing

    private func court(in size: CGSize) -> Path {
        var path = Path()
        let rect = CGRect(origin: .zero, size: size)
        path.addRect(rect)
        return path
    }

    private func courtLines(in size: CGSize) -> Path {
        var path = Path()
        let w = size.width
        let h = size.height

        // Half court baseline at bottom, midcourt at top
        path.addRect(CGRect(x: 0, y: 0, width: w, height: h))

        // Center line
        path.move(to: CGPoint(x: 0, y: h/2))
        path.addLine(to: CGPoint(x: w, y: h/2))

        // Three-point arc (approximate)
        let arcCenter = CGPoint(x: w/2, y: h - h*0.2)
        path.addArc(center: arcCenter, radius: min(w, h) * 0.35, startAngle: .degrees(200), endAngle: .degrees(-20), clockwise: true)

        // Free throw circle
        let ftCenter = CGPoint(x: w/2, y: h - h*0.35)
        path.addEllipse(in: CGRect(x: ftCenter.x - 50, y: ftCenter.y - 50, width: 100, height: 100))

        // Key/paint
        let keyWidth: CGFloat = min(w * 0.4, 180)
        let keyHeight: CGFloat = h * 0.35
        path.addRect(CGRect(x: (w - keyWidth)/2, y: h - keyHeight, width: keyWidth, height: keyHeight))

        return path
    }

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
