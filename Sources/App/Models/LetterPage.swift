//
//  LetterPage.swift
//  App
//
//  Created by tigeriv on 10/30/18.
//

import Foundation

final class LetterPage: Codable {
    let letterTitle: String?
    let children: [String]?
    let ocrText: String?
    init (title: String?, children: [String]?, ocrText: String?)
    {
        self.letterTitle = title
        self.children = children
        self.ocrText = ocrText
    }
}
