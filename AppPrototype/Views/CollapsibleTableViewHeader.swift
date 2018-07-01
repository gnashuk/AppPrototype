//
//  CollapsibleTableViewHeader.swift
//  AppPrototype
//
//  Created by Oleg Gnashuk on 6/17/18.
//  Copyright © 2018 Oleg Gnashuk. All rights reserved.
//

import UIKit

protocol CollapsibleTableViewHeaderDelegate {
    func toggleSection(_ header: CollapsibleTableViewHeader, section: Int)
}

class CollapsibleTableViewHeader: UITableViewHeaderFooterView {
    var delegate: CollapsibleTableViewHeaderDelegate?
    var section: Int = 0
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var arrowLabel: UILabel! {
        didSet {
            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CollapsibleTableViewHeader.tapHeader(_:))))
        }
    }
    
    override func awakeFromNib() {
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(CollapsibleTableViewHeader.tapHeader(_:))))
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func tapHeader(_ gestureRecognizer: UITapGestureRecognizer) {
        if let cell = gestureRecognizer.view as? CollapsibleTableViewHeader {
            delegate?.toggleSection(self, section: cell.section)
        }
    }
    
    func setCollapsed(_ collapsed: Bool) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.toValue = collapsed ? CGFloat.pi : 0.0
        animation.duration = 0.2
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        arrowLabel.layer.add(animation, forKey: nil)
    }
}
