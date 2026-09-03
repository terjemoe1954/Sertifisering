import SwiftUI
import PencilKit

struct SignatureEditor: View {
    let title: String
    @Binding var drawing: PKDrawing
    @State private var isPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))

            Button {
                isPresented = true
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                        .fill(.clear)
                        .frame(height: 120)

                    if drawing.bounds.isEmpty {
                        Text("Trykk for å signere")
                            .foregroundStyle(.secondary)
                    } else {
                        Image(uiImage: drawing.image(from: drawing.bounds, scale: 2.0))
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .frame(maxWidth: .infinity, maxHeight: 100)
                    }
                }
            }
            .buttonStyle(.plain)

            if !drawing.bounds.isEmpty {
                Button("Nullstill signatur", role: .destructive) {
                    drawing = PKDrawing()
                }
            }
        }
        .sheet(isPresented: $isPresented) {
            SignatureCanvasSheet(title: title, drawing: $drawing)
        }
    }
}

private struct SignatureCanvasSheet: View {
    let title: String
    @Binding var drawing: PKDrawing
    @Environment(\.dismiss) private var dismiss
    @State private var workingDrawing = PKDrawing()

    var body: some View {
        NavigationStack {
            SignatureCanvasRepresentable(drawing: $workingDrawing)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Lukk") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Tøm") {
                            workingDrawing = PKDrawing()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Lagre") {
                            drawing = workingDrawing
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    workingDrawing = drawing
                }
        }
    }
}

private struct SignatureCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.backgroundColor = .systemBackground
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .label, width: 4)
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding private var drawing: PKDrawing

        init(drawing: Binding<PKDrawing>) {
            _drawing = drawing
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
        }
    }
}
