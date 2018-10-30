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
    
    var authorPlaceholder: String?
    var author: String?
    
    var descriptionArray: [String]?
    var description: String?
    
    var datePlaceholder: String?
    var date: String?
    
    var cityPlaceholder: String?
    var statePlaceholder: String?
    var location: String?
    
    var pid: String
    
    enum CodingKeys: String, CodingKey {
        case titleArray = "dc.title"
        case title = "title"
        case authorPlaceholder = "mods_name_personal_author_namePart_s"
        case author = "author"
        case descriptionArray = "dc.description"
        case description = "description"
        case pid = "PID"
        case datePlaceholder = "mods_originInfo_dateCreated_s"
        case date = "date"
        case cityPlaceholder = "mods_subject_hierarchicalGeographic_city_s"
        case statePlaceholder = "mods_subject_hierarchicalGeographic_state_s"
        case location = "location"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        titleArray = try container.decode([String].self, forKey: .titleArray)
        title = titleArray![0]
        
        pid = try container.decode(String.self, forKey: .pid)
        
        do {
            authorPlaceholder = try container.decode(String.self, forKey: .authorPlaceholder)
            author = authorPlaceholder
        } catch {
            debugPrint("No author listed.")
        }
        
        do {
            datePlaceholder = try container.decode(String.self, forKey: .datePlaceholder)
            date = datePlaceholder
        } catch {
            debugPrint("No date listed.")
        }
        
        do {
            cityPlaceholder = try container.decode(String.self, forKey: .cityPlaceholder)
            statePlaceholder = try container.decode(String.self, forKey: .statePlaceholder)
        } catch {
            debugPrint("No location listed.")
        }
        
        if cityPlaceholder?.count ?? 0 > 0 && statePlaceholder?.count ?? 0 > 0 {
            location = cityPlaceholder! + ", " + statePlaceholder!
        } else if cityPlaceholder?.count ?? 0 > 0 {
            location = cityPlaceholder
        } else if statePlaceholder?.count ?? 0 > 0 {
            location = statePlaceholder
        }
        
        do {
            descriptionArray = try container.decode([String].self, forKey: .descriptionArray)
            description = descriptionArray![0]
        } catch {
            debugPrint("No description listed.")
        }
    }
}
