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
    let relatedItems: [relatedItem]?

    init (title: String?, children: [String]?, ocrText: String?, numPages: Int?, metadata: docArray?, relatedItems: [relatedItem]?)
    {
        self.letterTitle = title
        self.children = children
        self.ocrText = ocrText
        self.numPages = numPages ?? 0
        self.metadata = metadata
        self.relatedItems = relatedItems
    }
}

final class relatedItem: Codable {
    let id: String
    let title: String
    let translatedID: String
    init(id: String, title: String) {
        self.id = id;
        self.title = title;
        self.translatedID = id.replacingOccurrences(of: ":", with: "-")
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

final class Loc: Codable {
    let city: String
    let state: String
    let country: String
    let lat: Double
    let long: Double
    let timesOcc: Int
    init (city: String, state: String, country: String, lat: Double, long: Double, timesOcc: Int) {
        self.city = city
        self.state = state
        self.country = country
        self.lat = lat
        self.long = long
        self.timesOcc = timesOcc
    }
}

final class MapPage: Codable {
    let places: [Loc]
    let numPlaces: Int
    init (places: [Loc], numPlaces: Int) {
        self.places = places
        self.numPlaces = numPlaces
    }
}
