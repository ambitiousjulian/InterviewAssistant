//
//  ScoreCard.swift
//  InterviewAssistant
//
//  Created by j0c1epm on 1/15/25.
//
import SwiftUI

struct ScoreCard: View {
    let score: Int
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Overall Performance")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 10)
                    .stroke(scoreColor, lineWidth: 10)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                Text("\(score)/10")
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private var scoreColor: Color {
        switch score {
        case 0...4: return .red
        case 5...7: return .orange
        default: return .green
        }
    }
}

struct FeedbackSection: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
}

struct DetailedFeedbackSection: View {
    let feedback: [QuestionFeedback]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Feedback")
                .font(.headline)
            
            ForEach(feedback, id: \.questionIndex) { feedback in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Question \(feedback.questionIndex + 1)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(feedback.feedback)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
}
