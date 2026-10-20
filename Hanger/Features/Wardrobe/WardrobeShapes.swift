import SwiftUI

struct HangerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 2))
        path.addQuadCurve(to: CGPoint(x: rect.midX + 4, y: rect.minY + 7), control: CGPoint(x: rect.midX + 6, y: rect.minY + 1))
        path.addLine(to: CGPoint(x: rect.midX - 12, y: rect.maxY - 3))
        path.addQuadCurve(to: CGPoint(x: rect.midX + 12, y: rect.maxY - 3), control: CGPoint(x: rect.midX, y: rect.maxY - 9))
        path.addLine(to: CGPoint(x: rect.midX - 4, y: rect.minY + 7))
        return path
    }
}

struct GarmentBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.28, y: rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.width * 0.12, y: rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.width * 0.02, y: rect.height * 0.38))
        path.addLine(to: CGPoint(x: rect.width * 0.18, y: rect.height * 0.46))
        path.addLine(to: CGPoint(x: rect.width * 0.27, y: rect.height * 0.35))
        path.addLine(to: CGPoint(x: rect.width * 0.27, y: rect.height * 0.98))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.73, y: rect.height * 0.98), control: CGPoint(x: rect.midX, y: rect.height * 1.02))
        path.addLine(to: CGPoint(x: rect.width * 0.73, y: rect.height * 0.35))
        path.addLine(to: CGPoint(x: rect.width * 0.82, y: rect.height * 0.46))
        path.addLine(to: CGPoint(x: rect.width * 0.98, y: rect.height * 0.38))
        path.addLine(to: CGPoint(x: rect.width * 0.88, y: rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.height * 0.08))
        path.closeSubpath()
        return path
    }
}
