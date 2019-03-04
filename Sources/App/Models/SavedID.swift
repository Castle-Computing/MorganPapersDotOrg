import Vapor

final class SavedID: Codable {
    let reklQuery: String
    let islandoraQuery: String
    let cpscaQuery: String

    init(reklQuery: String, islandoraQuery: String, cpscaQuery: String) {
        self.reklQuery = reklQuery
        self.islandoraQuery = islandoraQuery
        self.cpscaQuery = cpscaQuery
    }
}

final class IDArrays: Codable {
    let reklArray: [String]
    let islandoraArray: [String]
    let cpscaArray: [String]
    let url: String
    init(SavedLetters: SavedID, restrictLength: Bool = true) {
        self.reklArray = SavedLetters.reklQuery.components(separatedBy: ",")
        self.islandoraArray = SavedLetters.islandoraQuery.components(separatedBy: ",")
        self.cpscaArray = SavedLetters.cpscaQuery.components(separatedBy: ",")
        var queryingURL = "https://digital.lib.calpoly.edu/islandora/rest/v1/solr/"
        for identifier in self.reklArray{
            queryingURL.append("PID:\"rekl:" + identifier + "\"")
            queryingURL.append(" OR ")
        }
        for identifier in self.islandoraArray{
            queryingURL.append("PID:\"islandora:" + identifier + "\"")
            queryingURL.append(" OR ")
        }
        for identifier in self.cpscaArray{
            queryingURL.append("PID:\"cpsca:" + identifier + "\"")
            queryingURL.append(" OR ")
        }
        var truncated = queryingURL.prefix(queryingURL.count - 4)
        
        if(restrictLength) {
            truncated += "?rows=15&omitHeader=true&wt=json&start=0"
        } else {
            truncated += "?omitHeader=true&wt=json"
        }
        
        self.url = String(truncated)
    }
}

final class JSONBuilder {
  let date : String
  var datearray : [String]
  let description : String
  let title : String
  let children : [String]?
  let url : String
  let start_date : [String: Any]
  let titleanddescription : [String: Any]
  let media: [String: Any]
  let events: [String: Any]


  //print(children)
  init(entry: docArray){
    self.date = entry.date ?? ""
    self.datearray = date.components(separatedBy: "-")
    self.description = entry.description ?? ""
    self.title = entry.title ?? ""
    self.children = entry.children
    if self.children?.isEmpty == false {
        self.url = "https://digital.lib.calpoly.edu/islandora/object/" + self.children![0] + "/datastream/JPG/view"
    }
    else{
      self.url = "https://digital.lib.calpoly.edu/islandora/rest/v1/object/" + entry.pid + "/datastream/TN"
    }
    while self.datearray.count < 3 {
        self.datearray.append("")
    }
    if self.datearray[2].contains("/"){
      self.datearray[2] = self.datearray[2].components(separatedBy: "/")[0]
    }
    self.start_date = ["year": self.datearray[0], "month": self.datearray[1], "day": self.datearray[2]]
    self.titleanddescription = ["headline": "<a href=" + "\"letter\\" + entry.pid + "\"" + ">" + self.title + "</p>","text": self.description]
    self.media = ["url" : self.url, "thumbnail" : self.url]
    self.events = ["start_date": self.start_date, "text": self.titleanddescription, "media" : self.media]
  }
}

final class MapJSONBuilder {
  let type: String
  let date : String
  var datearray : [String]
  let description : String
  let title : String
  let location : String
  var longitude : Int
  var latitude : Int
  let children : [String]?
  let url : String
  let titleanddescription : [String: Any]
  let media: [String: Any]
  let events: [String: Any]


  //print(children)
  init(entry: docArray){
    let data_city = ["Pleasanton", "San Francisco", "San Simeon", "New York", "Paris", "Berkeley", "Llantwit Major", "Brooklyn", "San Luis Obispo", "Los Angeles", "Salinas", "Cleveland", "Gallup", "North Newton", "Morristown", "McCloud", "Venice", "New York City", "Chicago", "Rome", "Chillicothe", "Boston", "Albuquerque", "Cambria", "La Junta", "Sacramento", "Pasadena", "Truckee", "Washington, D.C.", "Buffalo", "Washington, D. C.", "Jacksonville", "Santa Barbara", "Long Beach", "Havana", "Milano", "Madrid", "Winslow", "London", "Newton", "Santa Monica", "Washington D. C.", "New York", "Mount Vernon", "Bad Nauheim", "Chatham", "Dodge City", "Vienna", "Montello", "Oakland", "Monterey", "Mobile", "Ogden", "Chico", "Plattsburg", "Fresno"]
    let data_state = ["California", "California", "California", "New York", "empty", "California", "empty", "New York", "California", "California", "California", "Ohio", "New Mexico", "Kansas", "New Jersey", "California", "empty", "New York", "Illinois", "empty", "Illinois", "Massachusetts", "New Mexico", "California", "Colorado", "California", "California", "California", "empty", "New York", "empty", "Florida", "California", "California", "empty", "empty", "empty", "Arizona", "empty", "Kansas", "California", "empty", "California", "Virginia", "empty", "empty", "Kansas", "empty", "Nevada", "California", "California", "Alabama", "Utah", "California", "New York", "California"]
    let data_country = ["United States", "United States", "United States", "United States", "France", "United States", "Wales", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "Italy", "United States", "United States", "Italy", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "Cuba", "Italy", "Spain", "United States", "England", "United States", "United States", "United States", "United States", "United States", "Germany", "England", "United States", "Austria", "United States", "United States", "United States", "United States", "United States", "United States", "United States", "United States"]
    let data_longitude = [-121.8746789, -122.4192363, -121.1907533, -73.9871558, 2.3514992, -122.2728639, -3.4857779, -73.9495823, -120.6596156, -118.2427669, -121.6550372, -81.6934446, -108.7439489, -97.3455918, -74.4809492, -122.135266343, 12.3345898, -73.9871558, -87.6244212, 12.4853384, -89.4884384, -71.0582912, -106.6509851, -121.0807468, -103.5438321, -121.4943996, -118.1444779, -120.1832533, -77.0365625, -78.8783922, -77.0365625, -81.655651, -119.7026673, -118.158049315, -82.3589631, 9.1904984, -3.7035825, -110.6973572, -0.1276474, -97.3447244, -118.4965129, -77.0365625, -117.898451, -77.0967445, 8.7473608, 0.5292758, -100.0170787, 16.3725042, -114.1941804, -122.2713563, -121.8946388, -88.0430541, -111.9738429, -121.8374777, -73.45562, -119.708861261]
    let data_latitude = [37.6624312, 37.7792808, 35.6438587, 40.7308619, 48.8566101, 37.8708393, 51.4083212, 40.6501038, 35.2827525, 34.0536834, 36.6744117, 41.5051613, 35.5283573, 38.0722333, 40.7970384, 41.2497685, 45.4371908, 40.7308619, 41.8755616, 41.894802, 40.9161637, 42.3602534, 35.0841034, 35.5641381, 37.9850091, 38.5815719, 34.1476452, 39.327962, 38.8950092, 42.8867166, 38.8950092, 30.3321838, 34.4221319, 33.78538945, 23.135305, 45.4667971, 40.4167047, 35.0241874, 51.5073219, 38.0469166, 34.0250724, 38.8950092, 34.0143928, 38.7345867, 50.3681107, 51.3804845, 37.7527982, 48.2083537, 41.2614717, 37.8044557, 36.600256, 30.6943566, 41.2230048, 39.7284945, 44.69282, 36.7295295]
    self.location = entry.location ?? ""
    self.longitude = 0
    self.latitude = 0
    if self.location == "" {
      self.type = "Overview"
    }
    else{
      self.type = "Overview"
    }
    var cityname =  self.location.components(separatedBy: ",")[0]
    print(cityname)
    var index = data_city.index(of: cityname)
    self.date = entry.date ?? ""
    self.datearray = date.components(separatedBy: "-")
    self.description = entry.description ?? ""
    self.title = entry.title ?? ""
    self.children = entry.children
    if self.children?.isEmpty == false {
        self.url = "https://digital.lib.calpoly.edu/islandora/object/" + self.children![0] + "/datastream/JPG/view"
    }
    else{
      self.url = "https://digital.lib.calpoly.edu/islandora/rest/v1/object/" + entry.pid + "/datastream/TN"
    }
    while self.datearray.count < 3 {
        self.datearray.append("")
    }
    if self.datearray[2].contains("/"){
      self.datearray[2] = self.datearray[2].components(separatedBy: "/")[0]
    }
    self.titleanddescription = ["headline": "<a href=" + "\"letter\\" + entry.pid + "\"" + ">" + self.title + "</p>","text": self.description, "location": self.location]
    self.media = ["url" : self.url]
    if index != nil {
      var locationarray: [String : Any] = ["lon": data_longitude[index!], "lat": data_latitude[index!], "zoom": 10, "line": true]
      self.events = ["text": self.titleanddescription, "media" : self.media, "location": locationarray, "date": datearray[0]]
    }
    else{
      self.events = ["text": self.titleanddescription, "media" : self.media, "type": "Overview", "date": datearray[0]]
    }
  }
}
