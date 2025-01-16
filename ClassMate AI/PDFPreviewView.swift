//
//  PDFPreviewView.swift
//  ClassMate AI
//
//  Created by Kaan Ünsel on 16.01.2025.
//
import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    var pdfURL: URL

    var body: some View {
        PDFKitView(pdfURL: pdfURL)
            .navigationTitle("Preview PDF")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct PDFKitView: UIViewRepresentable {
    var pdfURL: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: pdfURL)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(url: pdfURL)
    }
}
