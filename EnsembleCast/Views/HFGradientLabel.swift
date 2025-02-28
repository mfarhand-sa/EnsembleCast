//
//  HFGradientLabel.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-27.
//

import UIKit

class HFGradientLabel: UILabel {
    var gradientColors: [CGColor] = []
    
    func applyGradientToAllText() {
        guard let text = self.text, let currentAttributedText = self.attributedText else { return }
        let attributedText = NSMutableAttributedString(attributedString: currentAttributedText)
        let gradientLayer = createGradientLayer()
        gradientLayer.frame = boundingRect(for: text)
        let image = gradientImage(from: gradientLayer)
        attributedText.addAttribute(.foregroundColor, value: UIColor(patternImage: image), range: NSRange(location: 0, length: text.count))
        self.attributedText = attributedText
    }

    
    func applyGradient(to word: String) {
        guard let text = self.text, let currentAttributedText = self.attributedText else { return }
        let attributedText = NSMutableAttributedString(attributedString: currentAttributedText)
        let range = (text as NSString).range(of: word)

        attributedText.addAttribute(.foregroundColor, value: self.textColor ?? .black, range: NSRange(location: 0, length: text.count))

        let gradientLayer = createGradientLayer()
        gradientLayer.frame = boundingRect(for: text, range: range)

        let image = gradientImage(from: gradientLayer)
        attributedText.addAttribute(.foregroundColor, value: UIColor(patternImage: image), range: range)

        self.attributedText = attributedText
    }

    private func createGradientLayer() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        return gradientLayer
    }
    
    private func boundingRect(for text: String, range: NSRange? = nil) -> CGRect {
        let attributedText = NSAttributedString(string: text, attributes: [.font: self.font ?? UIFont.systemFont(ofSize: 17)])
        let textBoundingRect = attributedText.boundingRect(with: CGSize(width: self.bounds.width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)

        if let range = range {
            let substring = (text as NSString).substring(with: range)
            let subAttrString = NSAttributedString(string: substring, attributes: [.font: self.font ?? UIFont.systemFont(ofSize: 17)])
            let subBoundingRect = subAttrString.boundingRect(with: CGSize(width: textBoundingRect.width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
            return CGRect(x: textBoundingRect.minX, y: textBoundingRect.minY, width: subBoundingRect.width, height: textBoundingRect.height)
        }

        return textBoundingRect
    }

    private func gradientImage(from layer: CAGradientLayer) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        layer.render(in: context)
        let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return gradientImage ?? UIImage()
    }
}
