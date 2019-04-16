//
//  GradientView.swift
//
//  Created by Paweł Nużka on 09/03/2019.
//

import Foundation

class GradientView: UIView {
    var startColor:   UIColor = UIColor.red.withAlphaComponent(0.5)
    var endColor:     UIColor = .clear
    
    override public class var layerClass: AnyClass { return CAGradientLayer.self }
    var gradientLayer: CAGradientLayer { return layer as! CAGradientLayer }

    override public func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
}
