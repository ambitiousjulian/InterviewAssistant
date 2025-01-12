import Foundation

struct Interview: Codable, Identifiable {
    let id: String
    let title: String
    let date: Date
    let questions: [String]
    let feedback: String?
    var status: Status
    
    enum Status: String, Codable {
        case scheduled, inProgress, completed
    }
}
