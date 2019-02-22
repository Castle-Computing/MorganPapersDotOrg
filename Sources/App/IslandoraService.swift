//
//  islandoraService.swift
//  App
//
//  Created by Ethan Kusters on 10/17/18.
//

import Foundation

class IslandoraService {
    public static let baseURL = "https://digital.lib.calpoly.edu/islandora/rest/v1/"
}


//URL associated with a PID, form rek:8156 etc.
func getObjectURL(rekl: String) -> String {
    let objectURL = "https://digital.lib.calpoly.edu/islandora/rest/v1/object/" + rekl
    return objectURL
}

//Get children associated with the PID of a bookCModel
//pid comes from a book model search, and is form rekl:8156 etc.
func getChildrenURL(pid: String) -> String {
    let childrenURL = "https://digital.lib.calpoly.edu/islandora/rest/v1/solr/" + "ancestors_ms:%22" + pid + "%22"
    return childrenURL
}

//URL associated with all books
//Can then use the book URL to get the children associated with it
func getBooksURL() -> String {
    return "https://digital.lib.calpoly.edu/islandora/rest/v1/solr/RELS_EXT_hasModel_uri_t:bookCModel%20AND%20ancestors_ms:%22rekl:morgan-ms010%22"
}

func getLetterURL(pid: String) -> String {
    return "https://digital.lib.calpoly.edu/islandora/rest/v1/solr/PID:%22" + pid + "%22"
}

//URL associated with books containing a certain term
func searchBookURL(encodedSearchTerm: String, start: Int) -> String {
    let itemURL = "https://digital.lib.calpoly.edu/islandora/rest/v1/solr/RELS_EXT_hasModel_uri_t:bookCModel%20AND%20ancestors_ms:%22rekl:morgan-ms010%22%20AND%20(dc.title:" + encodedSearchTerm + "%20OR%20dc.description:" + encodedSearchTerm + "%20OR%20OCR_BOOK_t:" + encodedSearchTerm + ")?rows=15&omitHeader=true&wt=json&start=" + String(start)
    return itemURL
}
