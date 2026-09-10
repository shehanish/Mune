//
//  ContactPicker.swift
//  Mend
//
//  Created by Shehani Hansika on 29.05.26.
//


import SwiftUI
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    class Coordinator: NSObject, CNContactPickerDelegate {
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            // Get first phone number
            if let phone = contact.phoneNumbers.first?.value.stringValue,
               let url = URL(string: "tel://\(phone.filter { $0.isNumber })"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}