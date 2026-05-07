import SwiftUI

// MARK: - Premium Court Background

struct PremiumCourtBackground: View {
    var isHalfCourt: Bool = false
    
    var body: some View {
        ZStack {
            // Premium dark blueprint background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.08, blue: 0.12), Color(red: 0.02, green: 0.04, blue: 0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Court Lines with neon glow
            CourtLinesShape(isHalfCourt: isHalfCourt)
                .stroke(Color.cyan.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .shadow(color: Color.cyan, radius: 4, x: 0, y: 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: isHalfCourt ? 12 : 0))
        .overlay(
            RoundedRectangle(cornerRadius: isHalfCourt ? 12 : 0)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Court Lines Shape

struct CourtLinesShape: Shape {
    var isHalfCourt: Bool
    
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        
        if isHalfCourt {
            // --- HALF COURT (Vertical layout) ---
            
            // Outer boundary
            p.addRect(CGRect(x: 0, y: 0, width: w, height: h))
            
            // Paint/Key
            let keyW = w * 0.35
            let keyH = h * 0.4
            p.addRect(CGRect(x: (w - keyW)/2, y: h - keyH, width: keyW, height: keyH))
            
            // FT Circle (top half)
            let ftCenter = CGPoint(x: w/2, y: h - keyH)
            p.move(to: CGPoint(x: ftCenter.x + keyW/2, y: ftCenter.y))
            p.addArc(center: ftCenter, radius: keyW/2, startAngle: .zero, endAngle: .degrees(180), clockwise: true)
            
            // FT Circle (bottom half - dashed in real life, solid here for simplicity)
            p.move(to: CGPoint(x: ftCenter.x + keyW/2, y: ftCenter.y))
            p.addArc(center: ftCenter, radius: keyW/2, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
            
            // 3-Point Line
            let cornerW = w * 0.08
            let cornerH = h * 0.25
            
            // Left corner
            p.move(to: CGPoint(x: cornerW, y: h))
            p.addLine(to: CGPoint(x: cornerW, y: h - cornerH))
            
            // Right corner
            p.move(to: CGPoint(x: w - cornerW, y: h))
            p.addLine(to: CGPoint(x: w - cornerW, y: h - cornerH))
            
            // 3-Point Arc
            // We connect from the right corner line up to the left corner line
            p.addArc(
                center: CGPoint(x: w/2, y: h - h * 0.05), // Basket approx location
                radius: w * 0.42,
                startAngle: .degrees(360 - 20),
                endAngle: .degrees(180 + 20),
                clockwise: true
            )
            
            // Hoop & Backboard
            p.move(to: CGPoint(x: w/2 - 20, y: h - h * 0.05))
            p.addLine(to: CGPoint(x: w/2 + 20, y: h - h * 0.05))
            p.addEllipse(in: CGRect(x: w/2 - 6, y: h - h * 0.05 - 12, width: 12, height: 12))
            
        } else {
            // --- FULL COURT (Horizontal layout) ---
            
            // Outer boundary
            p.addRect(CGRect(x: 0, y: 0, width: w, height: h))
            
            // Center line
            p.move(to: CGPoint(x: w/2, y: 0))
            p.addLine(to: CGPoint(x: w/2, y: h))
            
            // Center circle
            let center = CGPoint(x: w/2, y: h/2)
            let centerR = h * 0.15
            p.move(to: CGPoint(x: center.x + centerR, y: center.y))
            p.addArc(center: center, radius: centerR, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
            
            // Left Paint
            let keyW = w * 0.18
            let keyH = h * 0.35
            let paintY = (h - keyH)/2
            p.addRect(CGRect(x: 0, y: paintY, width: keyW, height: keyH))
            
            // Left FT Circle
            let leftFTCenter = CGPoint(x: keyW, y: h/2)
            p.move(to: CGPoint(x: leftFTCenter.x, y: leftFTCenter.y - keyH/2))
            p.addArc(center: leftFTCenter, radius: keyH/2, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
            
            // Left 3-Point Line
            let cornerH = h * 0.08
            let cornerW = w * 0.12
            p.move(to: CGPoint(x: 0, y: cornerH))
            p.addLine(to: CGPoint(x: cornerW, y: cornerH))
            p.move(to: CGPoint(x: 0, y: h - cornerH))
            p.addLine(to: CGPoint(x: cornerW, y: h - cornerH))
            
            p.addArc(
                center: CGPoint(x: w * 0.05, y: h/2),
                radius: h * 0.42,
                startAngle: .degrees(-75),
                endAngle: .degrees(75),
                clockwise: false
            )
            
            // Left Hoop & Backboard
            p.move(to: CGPoint(x: w * 0.05, y: h/2 - 15))
            p.addLine(to: CGPoint(x: w * 0.05, y: h/2 + 15))
            p.addEllipse(in: CGRect(x: w * 0.05, y: h/2 - 5, width: 10, height: 10))
            
            // Right Paint
            p.addRect(CGRect(x: w - keyW, y: paintY, width: keyW, height: keyH))
            
            // Right FT Circle
            let rightFTCenter = CGPoint(x: w - keyW, y: h/2)
            p.move(to: CGPoint(x: rightFTCenter.x, y: rightFTCenter.y - keyH/2))
            p.addArc(center: rightFTCenter, radius: keyH/2, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
            
            // Right 3-Point Line
            p.move(to: CGPoint(x: w, y: cornerH))
            p.addLine(to: CGPoint(x: w - cornerW, y: cornerH))
            p.move(to: CGPoint(x: w, y: h - cornerH))
            p.addLine(to: CGPoint(x: w - cornerW, y: h - cornerH))
            
            p.addArc(
                center: CGPoint(x: w - w * 0.05, y: h/2),
                radius: h * 0.42,
                startAngle: .degrees(180 - 75),
                endAngle: .degrees(180 + 75),
                clockwise: true
            )
            
            // Right Hoop & Backboard
            p.move(to: CGPoint(x: w - w * 0.05, y: h/2 - 15))
            p.addLine(to: CGPoint(x: w - w * 0.05, y: h/2 + 15))
            p.addEllipse(in: CGRect(x: w - w * 0.05 - 10, y: h/2 - 5, width: 10, height: 10))
        }
        
        return p
    }
}
