import Foundation
import AuthenticationServices

/// The signed-in user. `userID` is Apple's `sub` claim — stable forever and
/// identical to what the future web Sign In with Apple flow returns, so the
/// same identifier resolves to the same account across iOS + web (v2).
///
/// Persistence:
/// - `userID` lives in Keychain (survives app delete + reinstall on the same
///   device, same as Apple's recommendation for any non-secret identifier we
///   want to retain across reinstalls).
/// - `displayName` and `email` are cached in `UserDefaults` because Apple
///   returns them only on the very first sign-in for that Apple ID; we can't
///   re-fetch them on a later sign-in.
@Observable
@MainActor
final class UserSession {
    var userID: String?
    var displayName: String?
    var email: String?

    var isSignedIn: Bool { userID != nil }

    private let userIDKey = "userID"
    private let nameKey = "user.displayName"
    private let emailKey = "user.email"

    init() {
        load()
    }

    private func load() {
        userID = KeychainStorage.get(forKey: userIDKey)
        displayName = UserDefaults.standard.string(forKey: nameKey)
        email = UserDefaults.standard.string(forKey: emailKey)
    }

    func signIn(credential: ASAuthorizationAppleIDCredential) {
        // Apple's `user` property is the `sub` claim — stable across all
        // sign-ins for this Apple ID on this app's bundle.
        let id = credential.user
        KeychainStorage.set(id, forKey: userIDKey)
        userID = id

        // Apple only returns the human name on the FIRST sign-in for a given
        // Apple ID. Persist whatever we get; keep any cached values otherwise.
        if let name = credential.fullName {
            let formatted = PersonNameComponentsFormatter().string(from: name)
            if !formatted.isEmpty {
                UserDefaults.standard.set(formatted, forKey: nameKey)
                displayName = formatted
            }
        }
        if let mail = credential.email, !mail.isEmpty {
            UserDefaults.standard.set(mail, forKey: emailKey)
            email = mail
        }
    }

    func signOut() {
        KeychainStorage.delete(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: nameKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        userID = nil
        displayName = nil
        email = nil
    }

    /// Initials used by the avatar circle in the drawer. Falls back to "U" if
    /// no name has ever been captured (private-relay user who skipped name).
    var initials: String {
        guard let name = displayName, !name.isEmpty else { return "U" }
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().last?.first.map(String.init) ?? ""
        let combined = (first + last).uppercased()
        return combined.isEmpty ? "U" : combined
    }
}
