//
//  TripExporter.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import UIKit

@MainActor
enum TripExporter {

    static func exportPDF(for trip: Trip) throws -> URL {
        let safeName = trip.name
            .components(separatedBy: .alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName).pdf")

        let pageWidth: CGFloat = 612  // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 48
        let bounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let helper = DrawHelper(pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)

        try renderer.writePDF(to: url) { ctx in
            helper.beginPage(ctx)

            // Trip title
            helper.drawText(trip.name, font: .systemFont(ofSize: 26, weight: .bold), color: .label)
            helper.drawText(trip.formattedDateRange, font: .systemFont(ofSize: 13), color: .secondaryLabel)
            helper.advance(6)
            helper.drawRule(lineWidth: 1)
            helper.advance(16)

            // Notes oldest-first so the PDF reads like a diary
            let notes = (trip.notes ?? []).sorted { $0.createdDate < $1.createdDate }
            for note in notes {
                helper.ensureSpace(80, ctx: ctx)

                let stamp = note.createdDate.formatted(date: .abbreviated, time: .shortened)
                helper.drawText(stamp, font: .systemFont(ofSize: 10, weight: .medium), color: .tertiaryLabel)

                let images = (note.photos ?? []).compactMap { photo -> UIImage? in
                    guard let data = photo.thumbnailData else { return nil }
                    return UIImage(data: data)
                }
                if !images.isEmpty {
                    helper.drawPhotoRow(images, ctx: ctx)
                }

                let trimmed = note.text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    helper.drawMultilineText(trimmed, font: .systemFont(ofSize: 13), color: .label, ctx: ctx)
                }

                helper.advance(6)
                helper.drawRule(lineWidth: 0.25)
                helper.advance(12)
            }
        }

        return url
    }
}

// Carries mutable layout state through the synchronous PDF renderer closure.
private final class DrawHelper {
    let pageWidth: CGFloat
    let pageHeight: CGFloat
    let margin: CGFloat
    var y: CGFloat = 0

    var contentWidth: CGFloat { pageWidth - margin * 2 }

    init(pageWidth: CGFloat, pageHeight: CGFloat, margin: CGFloat) {
        self.pageWidth = pageWidth
        self.pageHeight = pageHeight
        self.margin = margin
    }

    func beginPage(_ ctx: UIGraphicsPDFRendererContext) {
        ctx.beginPage()
        y = margin
    }

    func ensureSpace(_ height: CGFloat, ctx: UIGraphicsPDFRendererContext) {
        if y + height > pageHeight - margin { beginPage(ctx) }
    }

    func advance(_ amount: CGFloat) { y += amount }

    func drawRule(lineWidth: CGFloat) {
        UIColor.separator.setStroke()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        path.lineWidth = lineWidth
        path.stroke()
    }

    func drawText(_ text: String, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: attrs)
        y += ceil(size.height) + 4
    }

    func drawMultilineText(_ text: String, font: UIFont, color: UIColor, ctx: UIGraphicsPDFRendererContext) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let measured = (text as NSString).boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs,
            context: nil
        )
        let height = ceil(measured.height)
        ensureSpace(height + 8, ctx: ctx)
        (text as NSString).draw(
            in: CGRect(x: margin, y: y, width: contentWidth, height: height),
            withAttributes: attrs
        )
        y += height + 8
    }

    func drawPhotoRow(_ images: [UIImage], ctx: UIGraphicsPDFRendererContext) {
        let size: CGFloat = 100
        let spacing: CGFloat = 8
        ensureSpace(size + 12, ctx: ctx)
        var x = margin
        for image in images {
            if x + size > pageWidth - margin {
                y += size + spacing
                x = margin
                ensureSpace(size, ctx: ctx)
            }
            image.draw(in: CGRect(x: x, y: y, width: size, height: size))
            x += size + spacing
        }
        y += size + 12
    }
}
