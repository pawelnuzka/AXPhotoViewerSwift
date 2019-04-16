//
//  CaptionView.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/28/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import UIKit

@objc(AXCaptionView) internal class CaptionView: GradientView, CaptionViewProtocol {
    
    open weak var delegate: CaptionViewDelegate?
    
    public var animateCaptionInfoChanges: Bool = true
    
    open var titleLabel = UILabel()
    open var descriptionLabel = UILabel()
    open var creditLabel = UILabel()
    
    fileprivate var titleSizingLabel = UILabel()
    fileprivate var descriptionSizingLabel = UILabel()
    fileprivate var creditSizingLabel = UILabel()
    
    fileprivate var visibleLabels: [UILabel]
    fileprivate var visibleSizingLabels: [UILabel]
    
    fileprivate var needsCaptionLayoutAnim = false
    fileprivate var isCaptionAnimatingIn = false
    fileprivate var isCaptionAnimatingOut = false
    
    fileprivate var isFirstLayout: Bool = true
    fileprivate var isBottomPadding = false
    fileprivate var isFontSizingEnabled = false
    
    open var defaultTitleAttributes: [String: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
            }
            
            let font =  UIFont(name: "Avenir-Heavy", size: 16) ??
                                        UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.bold)
            let textColor = UIColor.white
            
            return [
                convertFromNSAttributedStringKey(NSAttributedString.Key.font): font,
                convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor
            ]
        }
    }
    
    open var defaultDescriptionAttributes: [String: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
            }
            
            let font = UIFont(name: "Avenir-Medium", size: 14) ??
                                        UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.light)
            let textColor = UIColor.white
            
            return [
                convertFromNSAttributedStringKey(NSAttributedString.Key.font): font,
                convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor
            ]
        }
    }
    
    open var defaultCreditAttributes: [String: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .caption1,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .caption1).fontDescriptor
            }
            
            let font = UIFont(name: "Avenir-Medium", size: 14) ??
                                        UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.light)
            let textColor = UIColor.white
            
            return [
                convertFromNSAttributedStringKey(NSAttributedString.Key.font): font,
                convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): textColor
            ]
        }
    }
    
    init() {
        self.visibleLabels = [
            self.titleLabel,
            self.descriptionLabel,
            self.creditLabel
        ]
        self.visibleSizingLabels = [
            self.titleSizingLabel,
            self.descriptionSizingLabel,
            self.creditSizingLabel
        ]

        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        self.startColor = .clear
        self.endColor = UIColor.black.withAlphaComponent(0.5)
        
        self.titleSizingLabel.numberOfLines = 0
        self.descriptionSizingLabel.numberOfLines = 0
        self.creditSizingLabel.numberOfLines = 0
        
        self.titleLabel.textColor = .white
        self.titleLabel.numberOfLines = 0
        self.addSubview(self.titleLabel)
        
        self.descriptionLabel.textColor = .white
        self.descriptionLabel.numberOfLines = 0
        self.addSubview(self.descriptionLabel)
        
        self.creditLabel.textColor = .white
        self.creditLabel.numberOfLines = 0
        self.addSubview(self.creditLabel)
        
        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [weak self] (note) in
            self?.setNeedsLayout()
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open func applyCaptionInfo(attributedTitle: NSAttributedString?,
                               attributedDescription: NSAttributedString?,
                               attributedCredit: NSAttributedString?,
                               bottomPadding: Bool) {
        
        func makeAttributedStringWithDefaults(_ defaults: [String: Any], for attributedString: NSAttributedString?) -> NSAttributedString? {
            guard let defaultAttributedString = attributedString?.mutableCopy() as? NSMutableAttributedString else {
                return attributedString
            }
            
            var containsAttributes = false
            defaultAttributedString.enumerateAttributes(in: NSMakeRange(0, defaultAttributedString.length), options: []) { (attributes, range, stop) in
                guard attributes.count > 0 else {
                    return
                }
                
                containsAttributes = true
                stop.pointee = true
            }
            
            if containsAttributes {
                return attributedString
            }
            
            defaultAttributedString.addAttributes(convertToNSAttributedStringKeyDictionary(defaults), range: NSMakeRange(0, defaultAttributedString.length))
            return defaultAttributedString
        }
        
        self.isBottomPadding = bottomPadding
        let title = makeAttributedStringWithDefaults(self.defaultTitleAttributes, for: attributedTitle)
        let description = makeAttributedStringWithDefaults(self.defaultDescriptionAttributes, for: attributedDescription)
        let credit = makeAttributedStringWithDefaults(self.defaultCreditAttributes, for: attributedCredit)
        
        self.visibleSizingLabels = []
        self.visibleLabels = []

        self.titleSizingLabel.attributedText = title
        if !(title?.string.isEmpty ?? true) {
            self.visibleSizingLabels.append(self.titleSizingLabel)
            self.visibleLabels.append(self.titleLabel)
        }
        
        self.descriptionSizingLabel.attributedText = description
        if !(description?.string.isEmpty ?? true) {
            self.visibleSizingLabels.append(self.descriptionSizingLabel)
            self.visibleLabels.append(self.descriptionLabel)
        }
        
        self.creditSizingLabel.attributedText = credit
        if !(credit?.string.isEmpty ?? true) {
            self.visibleSizingLabels.append(self.creditSizingLabel)
            self.visibleLabels.append(self.creditLabel)
        }
        
        self.needsCaptionLayoutAnim = !self.isFirstLayout
        
        let newSize = self.computeSize(for: self.frame.size, applySizingLayout: false)
        self.delegate?.captionView(self, contentSizeDidChange: newSize)
        
        self.setNeedsLayout()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        self.computeSize(for: self.frame.size, applySizingLayout: true)
        
        weak var weakSelf = self
        func applySizingAttributes() {
            guard let uSelf = weakSelf else {
                return
            }
            
            uSelf.titleLabel.attributedText = uSelf.titleSizingLabel.attributedText
            uSelf.titleLabel.frame = uSelf.titleSizingLabel.frame
            uSelf.titleLabel.isHidden = (uSelf.titleSizingLabel.attributedText?.string.isEmpty ?? true)
            
            uSelf.descriptionLabel.attributedText = uSelf.descriptionSizingLabel.attributedText
            uSelf.descriptionLabel.frame = uSelf.descriptionSizingLabel.frame
            uSelf.descriptionLabel.isHidden = (uSelf.descriptionSizingLabel.attributedText?.string.isEmpty ?? true)
            
            uSelf.creditLabel.attributedText = uSelf.creditSizingLabel.attributedText
            uSelf.creditLabel.frame = uSelf.creditSizingLabel.frame
            uSelf.creditLabel.isHidden = (uSelf.creditSizingLabel.attributedText?.string.isEmpty ?? true)
        }
        
        if self.animateCaptionInfoChanges && self.needsCaptionLayoutAnim {
            let animateOut: () -> Void = { [weak self] in
                self?.titleLabel.alpha = 0
                self?.descriptionLabel.alpha = 0
                self?.creditLabel.alpha = 0
            }
            
            let animateOutCompletion: (_ finished: Bool) -> Void = { [weak self] (finished) in
                guard let uSelf = self, finished else {
                    return
                }
                
                applySizingAttributes()
                uSelf.isCaptionAnimatingOut = false
            }
            
            let animateIn: () -> Void = { [weak self] in
                self?.titleLabel.alpha = 1
                self?.descriptionLabel.alpha = 1
                self?.creditLabel.alpha = 1
            }
            
            let animateInCompletion: (_ finished: Bool) -> Void = { [weak self] (finished) in
                guard let uSelf = self, finished else {
                    return
                }
                
                uSelf.isCaptionAnimatingIn = false
            }
            
            if self.isCaptionAnimatingOut {
                return
            }
            
            self.isCaptionAnimatingOut = true
            UIView.animate(withDuration: AXConstants.frameAnimDuration / 2,
                           delay: 0,
                           options: [.beginFromCurrentState, .curveEaseOut], 
                           animations: animateOut) { [weak self] (finished) in
                            
                guard let uSelf = self, !uSelf.isCaptionAnimatingIn else {
                    return
                }
                
                animateOutCompletion(finished)
                UIView.animate(withDuration: AXConstants.frameAnimDuration / 2,
                               delay: 0, 
                               options: [.beginFromCurrentState, .curveEaseIn], 
                               animations: animateIn, 
                               completion: animateInCompletion)
            }
            
            self.needsCaptionLayoutAnim = false
            
        } else {
            applySizingAttributes()
        }
        
        self.isFirstLayout = false
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.computeSize(for: size, applySizingLayout: false)
    }
    
    @discardableResult fileprivate func computeSize(for constrainedSize: CGSize, applySizingLayout: Bool) -> CGSize {
        func makeFontAdjustedAttributedString(for attributedString: NSAttributedString?, fontTextStyle: UIFont.TextStyle) -> NSAttributedString? {
            guard let fontAdjustedAttributedString = attributedString?.mutableCopy() as? NSMutableAttributedString else {
                return attributedString
            }
            
            fontAdjustedAttributedString.enumerateAttribute(NSAttributedString.Key.font,
                                                            in: NSMakeRange(0, fontAdjustedAttributedString.length),
                                                            options: [], using: { [weak self] (value, range, stop) in
                guard let oldFont = value as? UIFont else {
                    return
                }
                
                var newFontDescriptor: UIFontDescriptor
                if #available(iOS 10.0, *) {
                    newFontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: fontTextStyle,
                                                                                 compatibleWith: self?.traitCollection)
                } else {
                    newFontDescriptor = UIFont.preferredFont(forTextStyle: fontTextStyle).fontDescriptor
                }
                                                                
                let newFont = oldFont.withSize(newFontDescriptor.pointSize)
                fontAdjustedAttributedString.removeAttribute(NSAttributedString.Key.font, range: range)
                fontAdjustedAttributedString.addAttribute(NSAttributedString.Key.font, value: newFont, range: range)
            })
            
            return fontAdjustedAttributedString.copy() as? NSAttributedString
        }
        
        if isFontSizingEnabled {
            self.titleSizingLabel.attributedText = makeFontAdjustedAttributedString(for: self.titleSizingLabel.attributedText,
                                                                                    fontTextStyle: .body)
            self.descriptionSizingLabel.attributedText = makeFontAdjustedAttributedString(for: self.descriptionSizingLabel.attributedText,
                                                                                          fontTextStyle: .body)
            self.creditSizingLabel.attributedText = makeFontAdjustedAttributedString(for: self.creditSizingLabel.attributedText,
                                                                                     fontTextStyle: .caption1)
        }
        
        let bottomPadding: CGFloat = self.isBottomPadding ? 65 : 10
        let VerticalPadding: CGFloat = 10
        let HorizontalPadding: CGFloat = 15
        let InterLabelSpacing: CGFloat = 2
        var yOffset: CGFloat = 0

        for (index, label) in self.visibleSizingLabels.enumerated() {
            var constrainedLabelSize = constrainedSize
            constrainedLabelSize.width -= (2 * HorizontalPadding)
            
            let labelSize = label.sizeThatFits(constrainedLabelSize)

            if index == 0 {
                yOffset += VerticalPadding
            } else {
                yOffset += InterLabelSpacing
            }
            
            let labelFrame = CGRect(origin: CGPoint(x: HorizontalPadding,
                                                    y: yOffset),
                                    size: labelSize)
            
            yOffset += labelFrame.size.height
            if index == (self.visibleSizingLabels.count - 1) {
                yOffset += (VerticalPadding + bottomPadding)
            }
            
            if applySizingLayout {
                label.frame = labelFrame
            }
        }
        
        return CGSize(width: constrainedSize.width, height: yOffset)
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
