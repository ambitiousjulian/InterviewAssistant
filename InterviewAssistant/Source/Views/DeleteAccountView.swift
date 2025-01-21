//
//  DeleteAccountView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/20/25.
//
import SwiftUI
import FirebaseAuth

struct DeleteAccountView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var password = ""
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var hasConfirmed = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Warning Icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                        .padding()
                    
                    // Warning Text
                    VStack(spacing: 12) {
                        Text("Delete Account")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("This action cannot be undone")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Information Card
                    VStack(alignment: .leading, spacing: 16) {
                        warningItem(icon: "xmark.circle.fill", text: "Your account will be permanently deleted")
                        warningItem(icon: "doc.fill", text: "All your data will be removed")
                        warningItem(icon: "person.fill.xmark", text: "You'll lose access to all features")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppTheme.surface)
                            .shadow(color: AppTheme.shadowLight, radius: 10)
                    )
                    
                    // Confirmation Checkbox
                    Toggle(isOn: $hasConfirmed) {
                        Text("I understand that this action is permanent")
                            .font(.subheadline)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.vertical)
                    
                    // Password Field
                    SecureField("Confirm password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // Delete Button
                    Button(action: deleteAccount) {
                        if isDeleting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Delete My Account")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        hasConfirmed && !password.isEmpty ?
                            Color.red : Color.red.opacity(0.3)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .disabled(!hasConfirmed || password.isEmpty || isDeleting)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func warningItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.red)
            Text(text)
                .font(.subheadline)
        }
    }
    
    private func deleteAccount() {
        isDeleting = true
        
        Task {
            do {
                try await FirebaseManager.shared.deleteUserAccount(password: password)
                
                await MainActor.run {
                    authViewModel.isAuthenticated = false
                    authViewModel.currentUser = nil
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .red : .gray)
                .font(.system(size: 20, weight: .semibold))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}
