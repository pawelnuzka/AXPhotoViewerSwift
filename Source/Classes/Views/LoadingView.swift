//
//  LoadingView.swift
//  AXPhotoViewer
//
//  Created by Alex Hill on 5/7/17.
//  Copyright © 2017 Alex Hill. All rights reserved.
//

import AXStateButton

@objc(AXLoadingView) open class LoadingView: UIView, LoadingViewProtocol {
    
    open fileprivate(set) lazy var indicatorView: UIView = UIActivityIndicatorView(style: .white)
    
    open fileprivate(set) var errorImageView: UIImageView?
    
    /// The image to show in the `errorImageView` when displaying an error.
    open var errorImage: UIImage? {
        get {
            let bundle = Bundle(for: LoadingView.self)
            return UIImage(named: "error", in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    open fileprivate(set) var errorLabel: UILabel?
    
    /// The error text to show when displaying an error.
    open var errorText: String {
        get {
            return NSLocalizedString("An error occurred while loading this image.", comment: "AXLoadingView - error text")
        }
    }
    
    /// The attributes that will get applied to the `errorText` when displaying an error.
    open var errorAttributes: [String: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .body).fontDescriptor
            }
            
            let font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.light)
            return [
                convertFromNSAttributedStringKey(NSAttributedString.Key.font): font
            ]
        }
    }
    
    open fileprivate(set) var retryButton: StateButton?
    
    /// The error text to show inside of the `retryButton` when displaying an error.
    open var retryText: String {
        return NSLocalizedString("Try again", comment: "AXLoadingView - retry text")
    }
    
    /// The attributes that will get applied to the `retryText` when displaying an error.
    open var retryAttributes: [String: Any] {
        get {
            var fontDescriptor: UIFontDescriptor
            if #available(iOS 10.0, *) {
                fontDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body,
                                                                          compatibleWith: self.traitCollection)
            } else {
                fontDescriptor = UIFont.preferredFont(forTextStyle: .caption1).fontDescriptor
            }
            
            let font = UIFont.systemFont(ofSize: fontDescriptor.pointSize, weight: UIFont.Weight.light)
            return [convertFromNSAttributedStringKey(NSAttributedString.Key.font): font]
        }
    }
    
    public fileprivate(set) var retryHandler: (() -> Void)?
    
    public init() {
        super.init(frame: .zero)
        
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.computeSize(for: self.frame.size, applySizingLayout: true)
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.computeSize(for: size, applySizingLayout: false)
    }
    
    @discardableResult fileprivate func computeSize(for constrainedSize: CGSize, applySizingLayout: Bool) -> CGSize {
        func makeAttributedStringWithAttributes(_ attributes: [String: Any], for attributedString: NSAttributedString?) -> NSAttributedString? {
            guard let newAttributedString = attributedString?.mutableCopy() as? NSMutableAttributedString else {
                return attributedString
            }
            
            newAttributedString.setAttributes(nil, range: NSMakeRange(0, newAttributedString.length))
            newAttributedString.addAttributes(convertToNSAttributedStringKeyDictionary(attributes), range: NSMakeRange(0, newAttributedString.length))
            
            return newAttributedString.copy() as? NSAttributedString
        }
        
        let ImageViewVerticalPadding: CGFloat = 20
        let VerticalPadding: CGFloat = 10
        var totalHeight: CGFloat = 0
        
        var indicatorViewSize: CGSize = .zero
        var errorImageViewSize: CGSize = .zero
        var errorLabelSize: CGSize = .zero
        var retryButtonSize: CGSize = .zero
        if let errorLabel = self.errorLabel, let retryButton = self.retryButton {
            if let errorImageView = self.errorImageView {
                errorImageViewSize = errorImageView.sizeThatFits(constrainedSize)
                totalHeight += errorImageViewSize.height
                totalHeight += ImageViewVerticalPadding
            }
            
            errorLabelSize = errorLabel.sizeThatFits(constrainedSize)
            totalHeight += errorLabelSize.height
            
            retryButton.setAttributedTitle(makeAttributedStringWithAttributes(self.retryAttributes,
                                                                              for: retryButton.attributedTitle(for: .normal)),
                                           for: .normal)
            
            let RetryButtonLabelPadding: CGFloat = 10.0
            retryButtonSize = retryButton.titleLabel?.sizeThatFits(constrainedSize) ?? .zero
            retryButtonSize.width += RetryButtonLabelPadding
            retryButtonSize.height += RetryButtonLabelPadding
            totalHeight += retryButtonSize.height
            totalHeight += VerticalPadding
        } else {
            indicatorViewSize = self.indicatorView.sizeThatFits(constrainedSize)
            totalHeight += totalHeight
        }
        
        if applySizingLayout {
            var yOffset: CGFloat = (constrainedSize.height - totalHeight) / 2.0
            
            if let errorLabel = self.errorLabel, let retryButton = self.retryButton {
                if let errorImageView = self.errorImageView {
                    errorImageView.frame = CGRect(origin: CGPoint(x: floor((constrainedSize.width - errorImageViewSize.width) / 2),
                                                                  y: floor(yOffset)),
                                                  size: errorImageViewSize)
                    yOffset += errorImageViewSize.height
                    yOffset += ImageViewVerticalPadding
                }
                
                errorLabel.frame = CGRect(origin: CGPoint(x: floor((constrainedSize.width - errorLabelSize.width) / 2),
                                                          y: floor(yOffset)),
                                          size: errorLabelSize)
                
                yOffset += errorLabelSize.height
                yOffset += VerticalPadding
                
                retryButton.frame = CGRect(origin: CGPoint(x: floor((constrainedSize.width - retryButtonSize.width) / 2),
                                                           y: floor(yOffset)),
                                           size: retryButtonSize)
                retryButton.setCornerRadius(retryButtonSize.height / 4.0, for: .normal)
            } else {
                self.indicatorView.frame = CGRect(origin: CGPoint(x: floor((constrainedSize.width - indicatorViewSize.width) / 2),
                                                                  y: floor(yOffset)),
                                                  size: indicatorViewSize)
            }
        }
        
        return CGSize(width: constrainedSize.width, height: totalHeight)
    }
    
    open func startLoading(initialProgress: CGFloat) {
        if self.indicatorView.superview == nil {
            self.addSubview(self.indicatorView)
            self.setNeedsLayout()
        }
        
        if let indicatorView = self.indicatorView as? UIActivityIndicatorView, !indicatorView.isAnimating {
            indicatorView.startAnimating()
        }
    }
    
    open func stopLoading() {
        if let indicatorView = self.indicatorView as? UIActivityIndicatorView, indicatorView.isAnimating {
            indicatorView.stopAnimating()
        }
    }
    
    open func updateProgress(_ progress: CGFloat) {
        // empty for now, need to create a progressive loading indicator
    }
    
    open func showError(_ error: Error, retryHandler: @escaping () -> Void) {
        self.stopLoading()
        
        self.retryHandler = retryHandler
        
        if let errorImage = self.errorImage {
            self.errorImageView = UIImageView(image: errorImage)
            self.addSubview(self.errorImageView!)
        } else {
            self.errorImageView?.removeFromSuperview()
            self.errorImageView = nil
        }
        
        errorLabel = UILabel()

        errorLabel?.text = self.errorText
        errorLabel?.textAlignment = .center
        errorLabel?.numberOfLines = 3
        errorLabel?.textColor = self.tintColor
        addSubview(self.errorLabel!)
        
        retryButton = StateButton()
        
        retryButton?.controlStateAnimationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        retryButton?.controlStateAnimationDuration = 0.1
        retryButton?.setAttributedTitle(NSAttributedString(string: self.retryText, attributes: convertToOptionalNSAttributedStringKeyDictionary(self.retryAttributes)),
                                             for: .normal)
        retryButton?.setBorderWidth(1.0, for: .normal)
        retryButton?.setBorderColor(self.tintColor, for: .normal)
        retryButton?.setAlpha(1.0, for: .normal)
        retryButton?.setAlpha(0.3, for: .highlighted)
        retryButton?.setTransformScale(1.0, for: .normal)
        retryButton?.setTransformScale(0.95, for: .highlighted)
        retryButton?.addTarget(self, action: #selector(retryButtonAction(_:)), for: .touchUpInside)
        addSubview(self.retryButton!)
        
        setNeedsLayout()
    }
    
    open func removeError() {
        if let errorImageView = self.errorImageView {
            errorImageView.removeFromSuperview()
            self.errorImageView = nil
        }
        
        if let errorLabel = self.errorLabel {
            errorLabel.removeFromSuperview()
            self.errorLabel = nil
        }
        
        if let retryButton = self.retryButton {
            retryButton.removeFromSuperview()
            self.retryButton = nil
        }
        
        self.retryHandler = nil
    }
    
    // MARK: - Button actions
    @objc fileprivate func retryButtonAction(_ sender: StateButton) {
        self.retryHandler?()
        self.retryHandler = nil
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

