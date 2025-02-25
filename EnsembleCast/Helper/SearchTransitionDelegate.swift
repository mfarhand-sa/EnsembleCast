//
//  SearchTransitionDelegate.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-25.
//

import UIKit

class SearchTransitionDelegate: NSObject, UIViewControllerAnimatedTransitioning, UINavigationControllerDelegate {
    private let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        if isPresenting {
            containerView.addSubview(toView)
            toView.alpha = 0
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                toView.alpha = 1
            }) { _ in
                transitionContext.completeTransition(true)
            }
        } else {
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                fromView.alpha = 0
            }) { _ in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(true)
            }
        }
    }
}
