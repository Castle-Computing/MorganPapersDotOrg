//
//  Query.swift
//  App
//
//  Created by Ethan Kusters on 1/30/19.
//

import Vapor

final class Query: Codable {
    var query: String?
    var allExplicit: String?
    var anyExplicit: String?
    var phraseExplicit: String?
    var noneExplicit: String?
    
    var author: String?
    var excludeAuthor = false
    
    var title: String?
    var excludeTitle = false
    
    var location: String?
    var excludeLocation = false
    
    var excludeLetters = false
    var excludeTelegrams = false
    var excludeDocuments = false
    var excludeDrawings = false
    var excludeInvoices = false
    
    var firstDate = "1915-01-01"
    var secondDate = "1945-12-31"
    var excludeDates = false
    
    init(queryParameters: QueryContainer) {
        if let queryParam = queryParameters[String.self, at: "query"] { query = queryParam }
        
        if let allExplicitParam = queryParameters[String.self, at: "all_explicit"] { allExplicit = allExplicitParam }
        
        if let anyExplicitParam = queryParameters[String.self, at: "any_explicit"] { anyExplicit = anyExplicitParam }
        
        if let phraseExplicitParam = queryParameters[String.self, at: "phrase_explicit"] { phraseExplicit = phraseExplicitParam }
        
        if let noneExplicitParam = queryParameters[String.self, at: "none_explicit"] { noneExplicit = noneExplicitParam }
        
        if let authorParam = queryParameters[String.self, at: "author"] { author = authorParam }
        
        if let excludeAuthorParam = queryParameters[Bool.self, at: "exclude_author"] { excludeAuthor = excludeAuthorParam }
        
        if let titleParam = queryParameters[String.self, at: "title"] { title = titleParam }
        
        if let excludeTitleParam = queryParameters[Bool.self, at: "exclude_title"] { excludeTitle = excludeTitleParam }
        
        if let locationParam = queryParameters[String.self, at: "location"] { location = locationParam }
        
        if let excludeLocationParam = queryParameters[Bool.self, at: "exclude_location"] { excludeLocation = excludeLocationParam }
        
        if let excludeLettersParam = queryParameters[Bool.self, at: "exclude_letters"] { excludeLetters = excludeLettersParam }
        
        if let excludeTelegramsParam = queryParameters[Bool.self, at: "exclude_telegrams"] { excludeTelegrams = excludeTelegramsParam }
        
        if let excludeDocumentsParam = queryParameters[Bool.self, at: "exclude_documents"] { excludeDocuments = excludeDocumentsParam }
        
        if let excludeDrawingsParam = queryParameters[Bool.self, at: "exclude_drawings"] { excludeDrawings = excludeDrawingsParam }
        
        if let excludeInvoicesParam = queryParameters[Bool.self, at: "exclude_invoices"] { excludeInvoices = excludeInvoicesParam  }
        
        if let firstDateParam = queryParameters[String.self, at: "first_date"] { firstDate = firstDateParam }
        
        if let secondDateParam = queryParameters[String.self, at: "second_date"] { secondDate = secondDateParam }
        
        if let excludeDatesParam = queryParameters[Bool.self, at: "exclude_dates"] { excludeDates = excludeDatesParam }
    }
}
