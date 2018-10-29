//
//  ResultPage.swift
//  App
//
//  Created by tigeriv on 10/25/18.
//

final class ResultPage: Codable {
    let searchTerm: String
    let searchResults: [docArray]
    let numberOfResults: Int
    let start: Int
    
    init(searchTerm: String, searchResults: [docArray], numResults: Int, start: Int) {
        self.searchTerm = searchTerm
        self.searchResults = searchResults
        self.numberOfResults = numResults
        self.start = start
    }
}

struct SearchResult: Codable {
    let response: searchResponse
}

struct searchResponse: Codable {
    let numFound: Int
    let start: Int
    let docs: [docArray]
}

final class docArray: Codable {
    var titleArray: [String]?
    var title: String?
    
    var authorArray: [String]?
    var author: String?
    
    var descriptionArray: [String]?
    var description: String?
    
    var pid: String
    
    enum CodingKeys: String, CodingKey {
        case titleArray = "dc.title"
        case title = "title"
        case authorArray = "dc.contributor"
        case author = "author"
        case descriptionArray = "dc.description"
        case description = "description"
        case pid = "PID"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        titleArray = try container.decode([String].self, forKey: .titleArray)
        title = titleArray![0]
        
        let reklPid = try container.decode(String.self, forKey: .pid)
        pid = String(reklPid.split(separator: ":")[1])
        
        do {
            authorArray = try container.decode([String].self, forKey: .authorArray)
            author = authorArray![0]
        } catch {
            debugPrint("No contributor listed.")
        }
        
        do {
            descriptionArray = try container.decode([String].self, forKey: .descriptionArray)
            description = descriptionArray![0]
        } catch {
            debugPrint("No description listed.")
        }
    }
}
