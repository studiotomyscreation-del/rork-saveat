import SwiftUI

/// Entry point for the SAVEAT PRO sign-up flow (§53 of the spec):
/// SIRET/SIREN identification → confirmation → responsible person's
/// details.
///
/// Presented as its own sheet with its own `NavigationStack`, deliberately
/// outside the app's `Route`/tab navigation — §5 of the spec is explicit
/// that the particulier's main navigation should never be cluttered with
/// professional screens.
struct ProSignUpContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            BusinessIdentifierView { record in
                path.append(record)
            }
            .navigationDestination(for: BusinessRegistryRecord.self) { record in
                ProfessionalDetailsView(record: record) {
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(S.Common.close.s) { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProSignUpContainerView()
}
