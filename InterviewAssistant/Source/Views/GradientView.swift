//
//  GradientView.swift
//  InterviewAssistant
//
//  Created by Julian Cajuste on 1/20/25.
//


import UIKit

class GradientView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    private func setupGradient() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0).cgColor, // Cotton Candy Pink
            UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0).cgColor, // Light Orange
            UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0).cgColor // Soft Blue
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
        gradientLayer.masksToBounds = true
        layer.insertSublayer(gradientLayer, at: 0)
    }
}
