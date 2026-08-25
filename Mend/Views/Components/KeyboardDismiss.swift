import SwiftUI
import UIKit

extension View {
    /// Programmatically resign first responder (dismiss the keyboard).
    func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
