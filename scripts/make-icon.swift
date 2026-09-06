import AppKit

let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let image = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        let context = NSGraphicsContext(bitmapImageRep: image)!
        NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
        let cg = context.cgContext
        cg.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
        let background = CGPath(roundedRect: CGRect(x: 60, y: 60, width: 904, height: 904), cornerWidth: 208, cornerHeight: 208, transform: nil)
        cg.addPath(background); cg.setFillColor(NSColor(calibratedRed: 0.13, green: 0.13, blue: 0.19, alpha: 1).cgColor); cg.fillPath()
        cg.setStrokeColor(NSColor(calibratedRed: 0.68, green: 0.65, blue: 1, alpha: 1).cgColor)
        cg.setLineWidth(43); cg.strokeEllipse(in: CGRect(x: 273, y: 273, width: 478, height: 478))
        cg.setLineWidth(32); cg.setLineCap(.round)
        for (a, b) in [(CGPoint(x: 512, y: 211), CGPoint(x: 512, y: 320)),
                       (CGPoint(x: 512, y: 704), CGPoint(x: 512, y: 813)),
                       (CGPoint(x: 211, y: 512), CGPoint(x: 320, y: 512)),
                       (CGPoint(x: 704, y: 512), CGPoint(x: 813, y: 512))] {
            cg.move(to: a); cg.addLine(to: b); cg.strokePath()
        }
        cg.setFillColor(NSColor(calibratedRed: 0.8, green: 0.78, blue: 1, alpha: 1).cgColor)
        cg.fillEllipse(in: CGRect(x: 463, y: 463, width: 98, height: 98))
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        try image.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
    }
}
