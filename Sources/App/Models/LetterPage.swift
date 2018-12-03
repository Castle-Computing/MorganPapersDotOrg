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
    let numPages: Int
    
    init (title: String?, children: [String]?, ocrText: String?, numPages: Int?)
    {
        self.letterTitle = title
        self.children = children
        self.ocrText = ocrText
        self.numPages = numPages ?? 0
    }
}
