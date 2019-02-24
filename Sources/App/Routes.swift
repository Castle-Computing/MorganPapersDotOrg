import Vapor

//All routes
public func routes(_ router: Router) throws {
    //Home screen, accessible without any additional URL parameters
    router.get { req -> EventLoopFuture<View> in
        let client = try req.client()
        
        //Get current Date
        let now = Date()
        let calendar = Calendar.current
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)
        
        let months = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
        var dayIndex = months[month - 1] + day - 1
        
        //Modify leap year since no letter
        if (dayIndex == 59) {
            dayIndex = 60
        }
        
        guard let currentQuery = Query.init(currentDayAsInt: dayIndex).getSolrSearch() else {
            return try req.view().render("home")
        }

        return client.get(currentQuery  , headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1")]))
            //flatMap unwraps the response and returns a SearchResult in the future
            .flatMap { response -> Future<SearchResult> in
                //Decode response into a SearchResult
                try response.content.decode(SearchResult.self)
            }
            //Take the SearchResult future (result), and try to render it
            .flatMap { results in
                //Render a view for the initial get request
                //results.leaf, pass a ResultPage
                var ltArr: [OIDTitle] = []
                
                for doc in results.response.docs {
                    guard let title = doc.title else { continue }
                    ltArr.append(OIDTitle(title: title, PID: doc.pid))
                }
                
                return try req.view().render("home", LODPageTitle(lettersIn: ltArr, numLetters: ltArr.count))
        }
    }
    
    router.get("letter", String.parameter) { req -> Future<View> in
        let letterPID = try req.parameters.next(String.self)
        let client = try req.client()
        let letterURL = getLetterURL(pid: letterPID)
        
        let searchResultRequest = client.get(letterURL, headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1")]))
            .flatMap { firstResponse -> Future<SearchResult> in
                return try firstResponse.content.decode(SearchResult.self)
        }
        
        let ocrDataRequest = client.get("https://digital.lib.calpoly.edu/islandora/object/" + letterPID + "/datastream/OCR_BOOK", headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1")]))
            .flatMap { secondResponse -> Future<Data> in
                return secondResponse.http.body.consumeData(on: req)
        }
        
        let relatedItemsRequest = client.get("https://digital.lib.calpoly.edu/islandora/object/" + letterPID + "/datastream/RELATED_OBJECTS", headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1")]))
            .flatMap { secondResponse -> Future<Data> in
                return secondResponse.http.body.consumeData(on: req)
        }
        
        return flatMap(searchResultRequest, ocrDataRequest, relatedItemsRequest) { (result: SearchResult, ocrData: Data, relatedItems: Data) in
            guard let letter = result.response.docs.first else {
                throw Abort(.badRequest)
            }
        
            var ocrText: String? = String(data: ocrData, encoding: .utf8)
            if (ocrText?.isEmpty ?? false) || ocrText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false { ocrText = nil }
            
            var relatedItemsText: String? = String(data: relatedItems, encoding: .utf8)
            if (relatedItemsText?.isEmpty ?? false) || relatedItemsText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false { relatedItemsText = nil }
            
            
            var relatedItems = [relatedItem]()
            
            if let unformatedRelatedItems = relatedItemsText?.split(separator: "\n") {
                for item in unformatedRelatedItems {
                    var split = item.components(separatedBy: ",")
                    guard (split.count >= 2) else { continue }
                    
                    relatedItems.append(relatedItem.init(id: split.remove(at: 0), title: split.joined(separator: ",")))
                }
            }
            
            return try req.view().render("letter", LetterPage(title: letter.title, children: letter.children, ocrText: ocrText, numPages: letter.children?.count, metadata: letter, relatedItems: relatedItems))
        }
    }

    router.get("help") { req -> Future<View> in
        return try req.view().render("help")
    }
    
    router.get("map") { req -> Future<View> in
        //These are tuples of distinct locations. Each tuple is city, state, country
        //Empty means there's nothing for the field
        let data_city = ["Pleasanton", "San Francisco", "San Simeon", "New York", "Paris", "Berkeley", "Llantwit Major", "Brooklyn", "San Luis Obispo", "Los Angeles", "Salinas", "Cleveland", "Gallup", "North Newton", "Morristown", "McCloud", "Venice", "New York City", "Chicago", "Rome", "Chillicothe", "Boston", "Albuquerque", "Cambria", "La Junta", "Sacramento", "Pasadena", "Truckee", "Washington, D.C.", "Buffalo", "Washington, D. C.", "Jacksonville", "Santa Barbara", "Long Beach", "Havana", "Milano", "Madrid", "Winslow", "London", "Newton", "Santa Monica", "Washington D. C.", "New York", "Mount Vernon", "Bad Nauheim", "Chatham", "Dodge City", "Vienna", "Montello", "Oakland", "Monterey", "Mobile", "Ogden", "Chico", "Plattsburg", "Fresno"]
        let data_state = ["California", "California", "California", "New York", "empty", "California", "empty", "New York", "California", "California", "California", "Ohio", "New Mexico", "Kansas", "New Jersey", "California", "empty", "New York", "Illinois", "empty", "Illinois", "Massachusetts", "New Mexico", "California", "Colorado", "California", "California", "California", "empty", "New York", "empty", "Florida", "California", "California", "empty", "empty", "empty", "Arizona", "empty", "Kansas", "California", "empty", "California", "Virginia", "empty", "empty", "Kansas", "empty", "Nevada", "California", "California", "Alabama", "Utah", "California", "New York", "California"]
        let data_country = ["United States", "United States", "United States", "United States", "France", "United States", "Wales", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "Italy", "United States", "United States", "Italy", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "Cuba", "Italy", "Spain", "United States", "England", "United States", "United States", "United States", "United States", "United States", "Germany", "England", "United States", "Austria", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States"]
        let data_longitude = [-121.8746789, -122.4192363, -121.1907533, -73.9871558, 2.3514992, -122.2728639, -3.4857779, -73.9495823, -120.6596156, -118.2427669, -121.6550372, -81.6934446, -108.7439489, -97.3455918, -74.4809492, -122.135266343, 12.3345898, -73.9871558, -87.6244212, 12.4853384, -89.4884384, -71.0582912, -106.6509851, -121.0807468, -103.5438321, -121.4943996, -118.1444779, -120.1832533, -77.0365625, -78.8783922, -77.0365625, -81.655651, -119.7026673, -118.158049315, -82.3589631, 9.1904984, -3.7035825, -110.6973572, -0.1276474, -97.3447244, -118.4965129, -77.0365625, -117.898451, -77.0967445, 8.7473608, 0.5292758, -100.0170787, 16.3725042, -114.1941804, -122.2713563, -121.8946388, -88.0430541, -111.9738429, -121.8374777, -73.45562, -119.708861261]
        let data_latitude = [37.6624312, 37.7792808, 35.6438587, 40.7308619, 48.8566101, 37.8708393, 51.4083212, 40.6501038, 35.2827525, 34.0536834, 36.6744117, 41.5051613, 35.5283573, 38.0722333, 40.7970384, 41.2497685, 45.4371908, 40.7308619, 41.8755616, 41.894802, 40.9161637, 42.3602534, 35.0841034, 35.5641381, 37.9850091, 38.5815719, 34.1476452, 39.327962, 38.8950092, 42.8867166, 38.8950092, 30.3321838, 34.4221319, 33.78538945, 23.135305, 45.4667971, 40.4167047, 35.0241874, 51.5073219, 38.0469166, 34.0250724, 38.8950092, 34.0143928, 38.7345867, 50.3681107, 51.3804845, 37.7527982, 48.2083537, 41.2614717, 37.8044557, 36.600256, 30.6943566, 41.2230048, 39.7284945, 44.69282, 36.7295295]
        let data_timesocc = [1, 315, 281, 170, 8, 2, 2, 47, 14, 328, 2, 5, 2, 3, 6, 7, 1, 1, 5, 3, 1, 7, 4, 2, 1, 2, 2, 1, 3, 1, 2, 1, 4, 1, 1, 1, 2, 1, 1, 1, 3, 2, 170, 2, 3, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 1]

        var locArr: [Loc] = []
        for (index, element) in data_city.enumerated() {
            locArr.append(Loc(city: data_city[index], state: data_state[index], country: data_country[index], lat: data_latitude[index], long: data_longitude[index], timesOcc: data_timesocc[index]))
        }
        return try req.view().render("map", MapPage(places: locArr, numPlaces: locArr.count))
    }
    
    
    router.get("about") { req -> Future<View> in
        return try req.view().render("about")
    }
    
    router.get("explore") { req -> Future<View> in
        return try req.view().render("explore")
    }
    
    //Adds new route, with search parameter.
    //Returns a view in the future
    router.get("search") { req -> Future<View> in
        //Attempt to obtain search term, otherwise abort
        //Receive the search term from the query
        //Request host/search?query=
        
        let currentQuery = Query.init(queryParameters: req.query, currentSearchURL: req.http.urlString)
        
        var page = req.query[Int.self, at: "page"] ?? 1
        if page < 1 {
            page = 1
        }
        
        let start = (page - 1) * 15
        
        //Create URL for Islandora entries with encoded search title and description
        //Using SOLR search parameters
        //Returns maximum 10 documents (rows=10)
        //Excludes header
        //let searchURL = searchBookURL(encodedSearchTerm: encodedSearchTerm, start: start)
        let searchURL = currentQuery.getSolrSearch(start: start)!
        
        //Create a client to send a request.get()
        let client = try req.client()
        
        //Sends an HTTP GET request to URL
        //The headers are required in the HTTP request, parameter User-Agent has value
        //MorganApp/0.1
        return client.get(searchURL, headers: HTTPHeaders.init([("User-Agent", "MorganApp/0.1"), ("Authorization", "Basic Y2FzdGxlX2NvbXB1dGluZzo4PnoqPUw0QmU2TWlEP1FB")]))
            //flatMap unwraps the response and returns a SearchResult in the future
            .flatMap { response -> Future<SearchResult> in
                //Decode response into a SearchResult
                try response.content.decode(SearchResult.self)
            }
            //Take the SearchResult future (result), and try to render it
            .flatMap { result in
                //Render a view for the initial get request
                //results.leaf, pass a ResultPage
                return try req.view().render("results", ResultPage(query: currentQuery, searchResults: result.response.docs, numResults: result.response.numFound, start: result.response.start, page: page))
        }
    }
}
