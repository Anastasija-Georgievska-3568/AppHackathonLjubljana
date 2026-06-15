import SwiftUI
import AuthenticationServices

/// First screen if the user isn't signed in. Hot Girl CEO wordmark + the
/// Apple-styled Continue with Apple button. No skip path — Apple is the
/// only auth method in v1.
struct AuthScreen: View {
    @Environment(UserSession.self) private var session

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                wordmark
                tagline
                    .padding(.top, 24)
                Spacer()
                signInButton
                privacyLine
                    .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Sections

    private var wordmark: some View {
        VStack(alignment: .leading, spacing: -8) {
            Text("DON'T")
                .font(DFFont.display(52))
                .foregroundStyle(Theme.ink)
                .tracking(-1.0)
            Text("FOLD.")
                .font(DFFont.display(52))
                .foregroundStyle(Theme.accent)
                .tracking(-1.0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tagline: some View {
        Text("practice the conversations that scare you.")
            .font(DFFont.body(15))
            .foregroundStyle(Theme.ink)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var signInButton: some View {
        SignInWithAppleButton(
            .continue,
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: handleResult
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 52)
        .cornerRadius(10)
    }

    private var privacyLine: some View {
        Text("we only store your sign-in id locally.")
            .font(DFFont.micro(10))
            .foregroundStyle(Theme.textSecondary)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Handlers

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            session.signIn(credential: credential)
        case .failure:
            // User cancellation lands here too — silent return.
            break
        }
    }
}
