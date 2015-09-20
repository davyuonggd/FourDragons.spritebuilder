//
//  MathHelper.swift
//  FourDragons
//
//  Created by DAVY UONG on 9/16/15.
//  Copyright © 2015 Apportable. All rights reserved.
//

import Foundation

func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
    return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
}