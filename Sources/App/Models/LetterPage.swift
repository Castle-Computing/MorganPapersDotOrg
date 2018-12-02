//
//  LetterPage.swift
//  App
//
//  Created by tigeriv on 10/30/18.
//
import Foundation

//For Pages
/*final class IslandoraObject: Codable {
 let pid: String
 let label: String
 let models: [String]
 let datastreams: [Datastream]
 }
 final class Datastream: Codable {
 let dsid: String
 let label: String
 let size: Int
 }*/

//For Books
struct AncestorSearchResult: Codable {
    let response: AncestorResponse
}

struct AncestorResponse: Codable {
    let numFound: Int
    let start: Int
    let docs: [PageArray]
}

struct PageArray: Codable {
    let PID: String
}

final class LetterPage: Codable {
    let parentLabel: String
    let numberResults: Int
    let data: [PageInfo]
    init (searchResults: Int, searchData: [PageInfo], parent: String)
    {
        self.numberResults = searchResults
        self.data = searchData
        self.parentLabel = parent
    }
}

final class PageInfo: Codable{
    let PID: String
    let index: Int
    init (index1: Int, PID1: String) {
        self.index = index1
        self.PID = PID1
    }
}
