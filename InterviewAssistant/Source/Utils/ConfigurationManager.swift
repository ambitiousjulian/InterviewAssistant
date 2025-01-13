//
//  ConfigurationManager.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/12/25.
//


// Source/Utils/ConfigurationManager.swift
import Foundation

enum ConfigurationManager {
    static func getEnvironmentVar(_ key: String) -> String? {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil),
              let contents = try? String(contentsOfFile: path) else {
            return nil
        }
        
        let lines = contents.components(separatedBy: .newlines)
        for line in lines {
            let parts = line.components(separatedBy: "=")
            if parts.count == 2 && parts[0] == key {
                return parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
}