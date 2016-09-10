//
//  Imagen.swift
//  Practica1
//
//  Created by Michel on 07/09/16.
//  Copyright © 2016 Telstock. All rights reserved.
//

import UIKit

class Imagen: UIImageView {

    override func awakeFromNib() {
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOpacity = 0.8
        layer.shadowOffset = CGSize(width: 3, height: 3)
    }
}
