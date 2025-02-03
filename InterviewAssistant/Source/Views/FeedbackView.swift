//
//  FeedbackView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 2/3/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FeedbackView: View {
    @State private var isAnimating = false
    @State private var feedbackText = ""
    @State private var contactEmail = ""
    @State private var selectedCategory: FeedbackCategory = .general
    @State private var isSubmitting = false
    @State private var showSuccessMessage = false
    @FocusState private var isFocused: Bool
    
    enum FeedbackCategory: String, CaseIterable {
        case general = "General"
        case userExperience = "User Experience"
        case technicalIssue = "Technical Issue"
        case featureRequest = "Feature Request"
        case other = "Other"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Gradient Background
                LinearGradient(
                    colors: [
                        AppTheme.primary.opacity(0.1),
                        AppTheme.secondary.opacity(0.1),
                        AppTheme.accent.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Animated Title
                        Text("Help Us Improve")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(AppTheme.text)
                            .multilineTextAlignment(.center)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                        
                        // Feedback Form
                        VStack(alignment: .leading, spacing: 15) {
                            // Category Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Feedback Category", systemImage: "tag.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.purple)
                                
                                Menu {
                                    Picker("Category", selection: $selectedCategory) {
                                        ForEach(FeedbackCategory.allCases, id: \.self) { category in
                                            Text(category.rawValue).tag(category)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCategory.rawValue)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .shadow(color: AppTheme.shadowLight, radius: 10)
                                    )
                                }
                            }
                            
                            // Feedback Text Editor
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Your Feedback", systemImage: "text.bubble.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.purple)
                                
                                TextEditor(text: $feedbackText)
                                    .frame(height: 200)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .shadow(color: AppTheme.shadowLight, radius: 10)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(feedbackText.isEmpty ? Color.gray.opacity(0.2) : AppTheme.primary, lineWidth: 1)
                                    )
                                    .focused($isFocused)
                            }
                            
                            // Contact Email
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Contact Email (Optional)", systemImage: "envelope.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.purple)
                                
                                TextField("Your email (optional)", text: $contactEmail)
                                    .textFieldStyle(ModernTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($isFocused)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.9))
                                .shadow(color: AppTheme.shadowLight, radius: 20)
                        )
                        
                        // Submit Button
                        Button(action: submitFeedback) {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                    Text("Submit Feedback")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: feedbackText.isEmpty ?
                                        [Color.gray.opacity(0.3)] :
                                        [AppTheme.primary, AppTheme.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: AppTheme.primary.opacity(0.3), radius: 10)
                        }
                        .disabled(feedbackText.isEmpty || isSubmitting)
                        .padding()
                        
                        // Success Message
                        if showSuccessMessage {
                            Text("Thank you for your feedback!")
                                .foregroundColor(.green)
                                .transition(.opacity)
                        }
                    }
                    .padding()
                }
                .simultaneousGesture(
                    DragGesture().onChanged { _ in
                        isFocused = false
                    }
                )
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }
    
    private func submitFeedback() {
        guard !feedbackText.isEmpty else { return }
        
        isFocused = false
        isSubmitting = true
        
        let db = Firestore.firestore()
        let userId = Auth.auth().currentUser?.uid ?? "anonymous"
        
        let feedbackData: [String: Any] = [
            "userId": userId,
            "category": selectedCategory.rawValue,
            "message": feedbackText,
            "email": contactEmail,
            "timestamp": FieldValue.serverTimestamp(),
            "deviceInfo": [
                "model": UIDevice.current.model,
                "systemVersion": UIDevice.current.systemVersion,
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            ]
        ]
        
        db.collection("userFeedback").addDocument(data: feedbackData) { error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    print("Error submitting feedback: \(error.localizedDescription)")
                    // Optionally show an error alert
                } else {
                    withAnimation {
                        showSuccessMessage = true
                        feedbackText = ""
                        contactEmail = ""
                    }
                    
                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showSuccessMessage = false
                        }
                    }
                }
            }
        }
    }
}
