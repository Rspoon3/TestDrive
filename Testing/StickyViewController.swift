//
//  StickyViewController.swift
//  Testing
//
//  Created by Richard Witherspoon on 7/8/20.
//  Copyright © 2020 Richard Witherspoon. All rights reserved.
//

import SwiftUI

class StickyViewController: UIViewController {
    
    lazy var dynamicAnimator: UIDynamicAnimator = {
        let dynamicAnimator = UIDynamicAnimator(referenceView: self.view)
        dynamicAnimator.setValue(true, forKey: "debugEnabled")
        return dynamicAnimator
    }()
    
    lazy var collision: UICollisionBehavior = {
        let collision = UICollisionBehavior(items: [self.orangeView])
        collision.translatesReferenceBoundsIntoBoundary = true
        return collision
    }()
    
    lazy var itemBehavior: UIDynamicItemBehavior = {
        let itemBehavior = UIDynamicItemBehavior(items: [self.orangeView])
        itemBehavior.density = 0.1
        itemBehavior.resistance = 2.0
        itemBehavior.friction = 0.3
        itemBehavior.allowsRotation = false
        return itemBehavior
    }()
    
    lazy var orangeView: UIView = {
        let widthHeight: CGFloat = 80.0
        let orangeView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: widthHeight, height: widthHeight))
        orangeView.backgroundColor = UIColor.orange
        orangeView.layer.cornerRadius = 8.0
        orangeView.layer.shadowColor = UIColor.black.cgColor
        orangeView.layer.shadowOpacity = 0.3
        orangeView.layer.shadowOffset = CGSize(width: 0, height: 2)
        orangeView.layer.shadowRadius = 4
        self.view.addSubview(orangeView)
        return orangeView
    }()
    
    lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(sender:)))
        return panGesture
    }()
    
    lazy var attachment: UIAttachmentBehavior = {
        let attachment = UIAttachmentBehavior(item: self.orangeView, attachedToAnchor: .zero)
        attachment.damping = 0.5
        attachment.frequency = 2.0
        return attachment
    }()
    
    lazy var fieldBehaviors: [UIFieldBehavior] = {
        var fieldBehaviors = [UIFieldBehavior]()
        for _ in 0 ..< 4 {
            let field = UIFieldBehavior.springField()
            field.addItem(self.orangeView)
            fieldBehaviors.append(field)
        }
        return fieldBehaviors
    }()
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dynamicAnimator.addBehavior(collision)
        dynamicAnimator.addBehavior(itemBehavior)
        
        for field in fieldBehaviors {
            dynamicAnimator.addBehavior(field)
        }
        
        orangeView.addGestureRecognizer(panGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Position the view initially in the top-right corner (like FaceTime)
        orangeView.center = CGPoint(x: view.bounds.width - 60, y: view.safeAreaInsets.top + 60)
        dynamicAnimator.updateItem(usingCurrentState: orangeView)
        
        // Set up field positions for debugging
        for (index, field) in fieldBehaviors.enumerated() {
            if index == 0 {
                field.position = CGPoint(x: view.bounds.midX / 2, y: view.bounds.height / 4)
            } else if index == 1 {
                field.position = CGPoint(x: view.bounds.width * 0.75, y: view.bounds.height / 4)
            } else if index == 2 {
                field.position = CGPoint(x: view.bounds.midX / 2, y: view.bounds.height * 0.75)
            } else {
                field.position = CGPoint(x: view.bounds.width * 0.75, y: view.bounds.height * 0.75)
            }
            
            field.region = UIRegion(size: CGSize(width: view.bounds.width / 2, height: view.bounds.height * 0.5))
        }
    }
    
    @objc func handlePan(sender: UIPanGestureRecognizer) {
        let location = sender.location(in: view)
        let velocity = sender.velocity(in: view)
        
        switch sender.state {
        case .began:
            // Attach to finger
            attachment.anchorPoint = location
            dynamicAnimator.addBehavior(attachment)
            
        case .changed:
            attachment.anchorPoint = location
            
        case .cancelled, .ended, .failed:
            // Remove attachment to finger
            dynamicAnimator.removeBehavior(attachment)
            
            // Add some velocity for natural movement
            itemBehavior.addLinearVelocity(velocity, for: self.orangeView)
            
        @unknown default:
            break
        }
    }
}
struct StickyViewControllerRepresentable: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> StickyViewController {
        return StickyViewController()
    }
    
    func updateUIViewController(_ uiViewController: StickyViewController, context: Context) {
        // Typically used to update data in the view controller from SwiftUI
    }
}


