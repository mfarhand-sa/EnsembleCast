
//
//  MovieCell.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-25.
//



import Foundation
import UIKit

// 1
class HFButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)

    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    

    override var isHighlighted: Bool {
        didSet {
            Haptic.play()
            UIView.animate(withDuration: 0.2, animations: {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            })
        }
    }

}
