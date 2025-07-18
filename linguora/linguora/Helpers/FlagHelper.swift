//
//  FlagHelper.swift
//  linguora
//
//  Created by Zoé Pilia on 18/07/2025.
//

import Foundation

func flag(for code: String) -> String {
    let base: UInt32 = 127397
    let uppercased = code.prefix(2).uppercased()
    var scalarView = String.UnicodeScalarView()

    for scalar in uppercased.unicodeScalars {
        if let flagScalar = UnicodeScalar(base + scalar.value) {
            scalarView.append(flagScalar)
        }
    }

    return String(scalarView)
}
