import UIKit
import MessageUI

@MainActor
enum FeedbackSender {
    /// Opens Gmail (or Mail via mailto) with To / Subject / Body already filled.
    static func openPrefillEmail(
        recipient: String,
        subject: String,
        body: String,
        onOpened: @escaping () -> Void,
        onUnavailable: @escaping (String) -> Void
    ) {
        UIPasteboard.general.string = recipient

        if let gmailURL = gmailComposeURL(recipient: recipient, subject: subject, body: body),
           UIApplication.shared.canOpenURL(gmailURL) {
            UIApplication.shared.open(gmailURL) { success in
                Task { @MainActor in
                    if success {
                        onOpened()
                    } else {
                        openMailto(recipient: recipient, subject: subject, body: body, onOpened: onOpened, onUnavailable: onUnavailable)
                    }
                }
            }
            return
        }

        openMailto(recipient: recipient, subject: subject, body: body, onOpened: onOpened, onUnavailable: onUnavailable)
    }

    static func send(
        recipient: String,
        subject: String,
        body: String,
        images: [UIImage],
        onMailFinished: @escaping (MFMailComposeResult) -> Void,
        onShareFinished: @escaping () -> Void,
        onUnavailable: @escaping (String) -> Void
    ) {
        UIPasteboard.general.string = recipient

        // Photos + Apple Mail: composer supports To + attachments.
        if !images.isEmpty, MFMailComposeViewController.canSendMail() {
            presentMailComposer(
                recipient: recipient,
                subject: subject,
                body: body,
                images: images,
                onFinished: onMailFinished,
                onUnavailable: onUnavailable
            )
            return
        }

        // Otherwise open Gmail/Mail with To already filled (URL schemes can't attach photos).
        openPrefillEmail(
            recipient: recipient,
            subject: subject,
            body: body,
            onOpened: onShareFinished,
            onUnavailable: { message in
                if !images.isEmpty {
                    presentShare(body: body, images: images, onFinished: onShareFinished)
                } else {
                    onUnavailable(message)
                }
            }
        )
    }

    static func presentMailComposer(
        recipient: String,
        subject: String,
        body: String,
        images: [UIImage],
        onFinished: @escaping (MFMailComposeResult) -> Void,
        onUnavailable: @escaping (String) -> Void
    ) {
        guard MFMailComposeViewController.canSendMail() else {
            onUnavailable("Mail isn’t available. Try Send feedback to open Gmail instead.")
            return
        }

        guard let presenter = topViewController() else {
            onUnavailable("Couldn't open Mail just now. Try Send feedback to open Gmail instead.")
            return
        }

        let composer = MFMailComposeViewController()
        let delegate = MailDelegate(onFinished: onFinished)
        mailDelegateRetain = delegate
        composer.mailComposeDelegate = delegate
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)

        for (index, image) in images.enumerated() {
            if let data = image.jpegData(compressionQuality: 0.72) {
                composer.addAttachmentData(data, mimeType: "image/jpeg", fileName: "mend-feedback-\(index + 1).jpg")
            }
        }

        composer.modalPresentationStyle = .formSheet
        presenter.present(composer, animated: true)
    }

    static func presentShare(
        body: String,
        images: [UIImage],
        onFinished: @escaping () -> Void
    ) {
        guard let presenter = topViewController() else {
            onFinished()
            return
        }

        var items: [Any] = [body]
        items.append(contentsOf: images)

        let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
        activity.completionWithItemsHandler = { _, _, _, _ in
            Task { @MainActor in
                onFinished()
            }
        }

        if let popover = activity.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = []
        }

        presenter.present(activity, animated: true)
    }

    private static func openMailto(
        recipient: String,
        subject: String,
        body: String,
        onOpened: @escaping () -> Void,
        onUnavailable: @escaping (String) -> Void
    ) {
        guard let url = mailtoComposeURL(recipient: recipient, subject: subject, body: body) else {
            onUnavailable("Couldn't open an email app. Is Gmail or Mail installed?")
            return
        }

        UIApplication.shared.open(url) { success in
            Task { @MainActor in
                if success {
                    onOpened()
                } else {
                    onUnavailable("Couldn't open an email app. Is Gmail or Mail installed?")
                }
            }
        }
    }

    private static func gmailComposeURL(recipient: String, subject: String, body: String) -> URL? {
        var components = URLComponents(string: "googlegmail://co")
        components?.queryItems = [
            URLQueryItem(name: "to", value: recipient),
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components?.url
    }

    private static func mailtoComposeURL(recipient: String, subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }

    private static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let resolvedBase = base ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController

        if let nav = resolvedBase as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = resolvedBase as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = resolvedBase?.presentedViewController {
            return topViewController(base: presented)
        }
        return resolvedBase
    }
}

@MainActor
private var mailDelegateRetain: MailDelegate?

@MainActor
private final class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {
    private let onFinished: (MFMailComposeResult) -> Void

    init(onFinished: @escaping (MFMailComposeResult) -> Void) {
        self.onFinished = onFinished
    }

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true) {
            Task { @MainActor in
                self.onFinished(result)
                mailDelegateRetain = nil
            }
        }
    }
}
