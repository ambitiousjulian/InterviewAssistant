import SwiftUI

// MARK: - Score Card
struct ScoreCard: View {
    let score: Int
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Overall Performance")
                .font(.title2)
                .fontWeight(.bold)
            
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 150, height: 150)
                
                // Score progress
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 10)
                    .stroke(scoreColor, lineWidth: 15)
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: score)
                
                // Score display
                VStack(spacing: 5) {
                    Text("\(score)")
                        .font(.system(size: 44, weight: .bold))
                    Text("out of 10")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Text(scoreDescription)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(scoreColor)
                .padding(.top, 5)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    private var scoreColor: Color {
        switch score {
        case 9...10: return .green
        case 7...8: return .blue
        case 5...6: return .orange
        default: return .red
        }
    }
    
    private var scoreDescription: String {
        switch score {
        case 9...10: return "Excellent Performance"
        case 7...8: return "Strong Performance"
        case 5...6: return "Good Performance"
        default: return "Needs Improvement"
        }
    }
}

// MARK: - Feedback Section
struct FeedbackSection: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            
            if items.isEmpty {
                Text("No feedback available")
                    .foregroundColor(.gray)
                    .padding(.vertical, 10)
            } else {
                ForEach(items.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .background(color)
                            .clipShape(Circle())
                        
                        Text(items[index])
                            .font(.body)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
}

// MARK: - Detailed Feedback Section
struct DetailedFeedbackSection: View {
    let feedback: [QuestionFeedback]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Question-by-Question Feedback")
                .font(.title3)
                .fontWeight(.bold)
            
            if feedback.isEmpty {
                Text("No detailed feedback available")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(feedback.indices, id: \.self) { index in
                    FeedbackCard(
                        questionNumber: index + 1,
                        score: feedback[index].score,
                        feedback: feedback[index].feedback
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
}

// MARK: - Feedback Card
struct FeedbackCard: View {
    let questionNumber: Int
    let score: Int
    let feedback: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Question \(questionNumber)")
                    .font(.headline)
                
                Spacer()
                
                ScoreBadge(score: score)
            }
            
            Text(feedback)
                .font(.body)
                .foregroundColor(.gray)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}

// MARK: - Score Badge
struct ScoreBadge: View {
    let score: Int
    
    var body: some View {
        Text("Score: \(score)/10")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(scoreColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(scoreColor.opacity(0.1))
            )
    }
    
    private var scoreColor: Color {
        switch score {
        case 9...10: return .green
        case 7...8: return .blue
        case 5...6: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview Provider
struct ScoreCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ScoreCard(score: 8)
            
            FeedbackSection(
                title: "Strengths",
                items: [
                    "Strong communication skills",
                    "Excellent problem-solving ability",
                    "Great team collaboration"
                ],
                color: .green
            )
            
            DetailedFeedbackSection(
                feedback: [
                    QuestionFeedback(questionIndex: 0, score: 9, feedback: "Excellent response with specific examples"),
                    QuestionFeedback(questionIndex: 1, score: 7, feedback: "Good answer but could provide more detail")
                ]
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
