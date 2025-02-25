//
//  EULAView.swift
//  InterviewAssistant
//
//  Created by j0c1epm on 1/20/25.
//
import SwiftUI

struct EULAView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var hasAgreed: Bool
    let onAgree: () -> Void
    
    @State private var hasScrolledToBottom = false
    @State private var showAgreeButton = false
    
    private let eulaContent: [(title: String, content: String)] = [
        ("1. License Grant", """
        CAJCODE LLC grants you a non-exclusive, non-transferable, limited, and revocable license to use the NextJob AI application ("App") for personal, non-commercial purposes. By downloading, installing, or using the App, you agree to be bound by this Agreement.
        """),
        
        ("2. Restrictions", """
        You may NOT:
        • Reverse-engineer, decompile, disassemble, or otherwise attempt to derive the App's source code
        • Copy, modify, distribute, or create derivative works of the App
        • Use the App for any unlawful or harmful purposes
        • Share your login credentials or allow unauthorized access to your account
        """),
        
        ("3. Fees and Payments", """
        App usage includes:
        • Free Tier: 6-10 free AI responses per month, including mock interviews and live-interview help.
        • Premium Plans:
            ◦ Monthly Subscription: $3.99/month – Unlimited AI mock interviews and live-interview help
        • Payments are non-refundable except as required by law.
        For billing issues, contact info@cajcode.com.
        """),
        
        ("4. User Data", """
        The App collects and stores the following user data:
        • Username and email for login
        • Resume information (if provided by the user)
        Use of this data is governed by the Privacy Policy.
        """),
        
        ("5. Intellectual Property", """
        The App, including all content, software, and trademarks, is the sole property of CAJCODE LLC. No ownership rights are transferred to the User.
        """),
        
        ("6. Termination", """
        CAJCODE LLC may terminate this Agreement and revoke your access to the App for any breach of this Agreement. Upon termination, you must stop using the App and delete all copies from your devices.
        """),
        
        ("7. Warranty Disclaimer", """
        The App is provided "as is" without any warranties, express or implied, including but not limited to fitness for a particular purpose or merchantability.
        """),
        
        ("8. Limitation of Liability", """
        To the maximum extent permitted by law, CAJCODE LLC shall not be liable for:
        • Indirect, incidental, or consequential damages
        • Loss of data, revenue, or profits arising from your use of the App
        """),
        
        ("9. Modifications", """
        CAJCODE LLC reserves the right to modify this Agreement at any time. Changes will be communicated through the App or by email. Continued use of the App constitutes acceptance of the updated Agreement.
        """),
        
        ("10. Governing Law", """
        This Agreement is governed by the laws of Florida. Any disputes shall be resolved in the courts of Broward County, Florida.
        """),
        
        ("11. Contact Information", """
        If you have questions about this Agreement, contact us at:
        Email: info@cajcode.com
        """)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.primary)
                            .symbolEffect(.bounce)
                        
                        Text("End-User License Agreement")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Please review our terms carefully")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // EULA Content
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                // Company Header
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("NextJob AI")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text("CAJCODE LLC")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("Effective Date: January 19, 2024")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.bottom)
                                
                                // EULA Sections
                                ForEach(eulaContent, id: \.title) { section in
                                    eulaSection(title: section.title, content: section.content)
                                }
                                
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                                    .onAppear {
                                        withAnimation(.easeIn(duration: 0.3)) {
                                            hasScrolledToBottom = true
                                        }
                                    }
                            }
                            .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(AppTheme.surface)
                                .shadow(color: AppTheme.shadowLight, radius: 10)
                        )
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            hasAgreed = true
                            onAgree()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text("I Agree to the Terms")
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(hasScrolledToBottom ? AppTheme.primary : AppTheme.primary.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .disabled(!hasScrolledToBottom)
                        
                        Button(action: { dismiss() }) {
                            Text("Decline")
                                .foregroundColor(AppTheme.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func eulaSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.primary)
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}
