import CloudKit
import SwiftUI
import UIKit

struct CompanyCloudSharingView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let share: CKShare

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = CloudKitSharingSupport.makeCompanySharingController(share: share)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        private let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Sertifisering firmadata"
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            dismiss()
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            dismiss()
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Kunne ikke lagre CloudKit-deling: \(error.localizedDescription)")
        }
    }
}
