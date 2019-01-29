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
    let metadata: docArray?
    
    init (title: String?, children: [String]?, ocrText: String?, numPages: Int?, metadata: docArray?)
    {
        self.letterTitle = title
        self.children = children
        self.ocrText = ocrText
        self.numPages = numPages ?? 0
        self.metadata = metadata
    }
}

final class LODPage: Codable {
    let letters: [String]?
    let numLetters: Int
    init (lettersIn: [String]?, numLetters: Int?) {
        self.letters = lettersIn
        self.numLetters = numLetters ?? 0
    }
}

final class LODPageTitle: Codable {
    let letters: [OIDTitle]?
    let numLetters: Int
    init (lettersIn: [OIDTitle]?, numLetters: Int?) {
        self.letters = lettersIn
        self.numLetters = numLetters ?? 0
    }
}

final class OIDTitle: Codable {
    let PID: String
    let title: String
    init (title: String, PID: String) {
        self.title = title
        self.PID = PID
    }
}
