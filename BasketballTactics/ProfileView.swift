import SwiftUI
import AuthenticationServices

struct ProfileView: View {
    @AppStorage("userId") private var userId: String = ""
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if isLoggedIn {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                        
                        Text("Welcome, \(userName.isEmpty ? "Coach" : userName)!")
                            .font(.title2)
                            .bold()
                        
                        Text("Your tactics and puzzles are synced securely with your Apple ID.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(role: .destructive) {
                            signOut()
                        } label: {
                            Text("Sign Out")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                        
                        Text("Save Your Progress")
                            .font(.title)
                            .bold()
                        
                        Text("Sign in with Apple to back up your puzzle progress and custom tactics across all your devices.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Native Apple Auth Button
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                handleAppleSignIn(result: result)
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                        
                        Text("We do not store or sell your data. Authentication is used solely for iCloud syncing.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 50)
                            .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // If this is the first time, we get the name
                if let givenName = appleIDCredential.fullName?.givenName {
                    userName = givenName
                }
                userId = appleIDCredential.user
                isLoggedIn = true
                print("Successfully signed in with Apple. User ID: \(userId)")
            }
        case .failure(let error):
            print("Apple Sign-In failed: \(error.localizedDescription)")
        }
    }
    
    private func signOut() {
        isLoggedIn = false
        userId = ""
        userName = ""
    }
}

#Preview {
    ProfileView()
}
