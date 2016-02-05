import SKMaps
import RealmSwift

class SearchService: NSObject {
  var searchHandler: ([SKSearchResult] -> ())!
  let maxResults = 20
  var packageCode: String!
  let varLock = dispatch_queue_create("SearchService.VarLock", nil)
  var searchRunning = false
  var threadCount = 0
  
  
  override init() {
    super.init()
    SKSearchService.sharedInstance().searchResultsNumber = 10000
    SKSearchService.sharedInstance().searchServiceDelegate = self
  }
  
  private func setPackageCode(regionId: String, countryId: String) {
    if regionId != countryId && DownloadService.hasMapPackage(regionId) {
      packageCode = regionId
    }
    else {
      packageCode = countryId
    }
  }
  
  func getCities(forCountry countryId: String? = nil, handler: (String, [SKSearchResult], (() -> ())?) -> ()) {
    if let countryId = countryId {
      setPackageCode(countryId, countryId: countryId)
      searchHandler = { results in
        
        if results.count == 0 { // error, repeat query
          print("Got no cities fir country \(countryId). Retrying query.")
          self.getCities(forCountry: countryId, handler: handler)
        }
        else {
          handler(countryId, results, nil)
        }
      }
      self.searchMapData(SKListLevel.CityList, searchString: "", parent: 0)
    }
    else {
      let mapPackages = SKMapsService.sharedInstance().packagesManager.installedOfflineMapPackages as! [SKMapPackage]
      if mapPackages.count > 0 {
        iterateThroughMapPackages(mapPackages, index: 0, handler: handler)
      }
      else {
        handler("noresults", [SKSearchResult](), nil)
      }
    }
  }
  
  func iterateThroughMapPackages(packages: [SKMapPackage], index: Int, handler: (String, [SKSearchResult], (() -> ())?) -> ())  {
    let mapPackage = packages[index]
    packageCode = mapPackage.name
    searchHandler = { results in
      
      if results.count == 0 { // error, repeat query
        print("Got no cities for country \(self.packageCode). Retrying query.")
        self.iterateThroughMapPackages(packages, index: index, handler: handler)
      }
      else {
        var callback: (() -> ())? = nil
        if index + 1 < packages.count {
          callback = {
            self.iterateThroughMapPackages(packages, index: index + 1, handler: handler)
          }
        }
        handler(mapPackage.name, results, callback)
      }
    }
    self.searchMapData(SKListLevel.CityList, searchString: "", parent: 0)
    
  }
  
  func getStreetsForCity(cityId: String, countryId: String, identifier: UInt64, searchString: String, handler: [SKSearchResult] -> ()) {
    setPackageCode(cityId, countryId: countryId)
    searchHandler = handler
    self.searchMapData(SKListLevel.StreetList, searchString: searchString, parent: identifier)
  }
  
  func onlineSearch(fullSearchString: String, regionId: String? = nil, countryId: String? = nil, gradual: Bool = false, handler: List<SimplePOI> -> ()) {
    
    let escapedString = fullSearchString.stringByAddingPercentEncodingWithAllowedCharacters(.URLPathAllowedCharacterSet())!
    NetworkUtil.getJsonFromUrl(ContentService.baseUrl + "/search/\(escapedString)", success: {
      json in
      
      let searchResults = self.parseSearchResults(json)
      
      dispatch_async(dispatch_get_main_queue()) {
        handler(searchResults)
      }
      }, failure: nil)
  }
  
  func parseSearchResults(json: JSON) -> List<SimplePOI> {
    let searchResults = List<SimplePOI>()
    for resultJson in json.array! {
      let searchResult = SimplePOI()
      searchResult.name = resultJson["name"].string!
      searchResult.location = resultJson["location"].string!
      searchResult.latitude = resultJson["latitude"].double!
      searchResult.longitude = resultJson["longitude"].double!
      searchResult.category = resultJson["category"].int!
      searchResult.listingId = resultJson["id"].string!
      searchResults.append(searchResult)
    }
    return searchResults
  }
  
  func bulkOfflineSearch(fullSearchString: String, regionId: String? = nil, countryId: String? = nil, handler: [SimplePOI] -> ()) {
    var allSearchResults = [SimplePOI]()
    offlineSearch(fullSearchString, regionId: regionId, countryId: countryId) {
      city, searchResults, nextCityHandler in
      
      allSearchResults.appendContentsOf(searchResults)
      
      if let nextCityHandler = nextCityHandler {
        nextCityHandler()
      }
      else {
        handler(allSearchResults)
      }
    }
  }
  
  func offlineSearch(fullSearchString: String, regionId: String? = nil, countryId: String? = nil, handler: (String, [SimplePOI], (() -> ())?) -> ()) {
    
    var threadId = 0
    SyncManager.synchronized(varLock) {
      self.threadCount += 1
      threadId = self.threadCount
    }
    let isCancelled: () -> Bool = {
      var isCancelled = false
      SyncManager.synchronized(self.varLock) {
        if threadId != self.threadCount {
          isCancelled = true
        }
      }
      if isCancelled {
        print("cancelling thread \(threadId), because there are \(self.threadCount)")
      }
      return isCancelled
    }
    
    SyncManager.run_async {
      
      print("Waiting for thread to unlock \(threadId)")
      SyncManager.block_until_condition(self, condition: {
        return self.searchRunning == false
        },
        after: {
          self.searchRunning = true
      })
      print("Got lock for thread \(threadId)")
      
      if isCancelled() {
        self.searchRunning = false
        return
      }
      
      var searchStrings = fullSearchString.characters.split{ $0 == " " }.map(String.init)
      searchStrings = searchStrings.sort { $0.characters.count > $1.characters.count }
      searchStrings = searchStrings.map {return $0.lowercaseString }
      let primarySearchString = searchStrings[0]
      let secondarySearchStrings = Array(searchStrings[1..<searchStrings.count])
      
      let countryId = countryId == nil ? regionId : countryId!
      print("offline searching for country: \(countryId)")
      
      self.getCities(forCountry: countryId) {
        packageId, cities, nextCountryHandler in
        
        print("Citiy packageId \(packageId)")
        print("Cities count \(cities.count)")
        var counter = 0
        var numberOfResults = 0
        
        self.packageCode = packageId
        self.searchHandler = {
          searchResults in
          
          print("Entering searchHandler")
          
          counter += 1
          
          if isCancelled() {
            self.searchRunning = false
            return
          }
          
          var resultsToParse = self.filterSearchResults(searchResults, secondarySearchStrings: secondarySearchStrings)
          var listIsFull = false
          if (numberOfResults + resultsToParse.count) >= self.maxResults {
            let willTake = self.maxResults - numberOfResults
            resultsToParse = Array(resultsToParse[0..<willTake])
            listIsFull = true
          }
          print("cites: \(cities.count)")
          let city = cities[counter - 1]
          let parsedResults = self.parseSearchResults(resultsToParse, city: city.name)
          numberOfResults += parsedResults.count
          
          if counter < cities.count && !listIsFull {
            
            handler(city.name, parsedResults) {
              let city = cities[counter]
              print("iterating to next city: \(city.name)")
              self.searchMapData(SKListLevel.StreetList, searchString: primarySearchString, parent: city.identifier)
            }
          }
          else if !listIsFull {

            if let nextCountryHandler = nextCountryHandler {
              handler(city.name, parsedResults) {
                nextCountryHandler()
              }
            }
            else {
              print("Finished thread: \(threadId)")
              self.searchRunning = false
              handler(city.name, parsedResults, nil)
            }
          }
          else {
            self.searchRunning = false
            handler(city.name, parsedResults, nil)
          }
        }
        
        if cities.count == 0 {
          print("No cities offline")
          self.searchRunning = false
        }
        else {
          let city = cities[counter]
          self.searchMapData(SKListLevel.StreetList, searchString: primarySearchString, parent: city.identifier)
        }
      }
    }
  }
  
  private func filterSearchResults(results: [SKSearchResult], secondarySearchStrings: [String]) -> [SKSearchResult] {
    if (secondarySearchStrings.count == 0 || results.count == 0) {
      return results
    }
    var filteredResults = [SKSearchResult]()
    for result in results {
      let nameParts = result.name.lowercaseString.characters.split{ $0 == " " }.map(String.init)
      
      if (secondarySearchStrings.reduce(true) {
        (acc, value) in
        
        return acc && nameParts.reduce(false) { $0 || $1.hasPrefix(value) }
        })
      {
        filteredResults.append(result)
      }
    }
    return filteredResults
  }
  
  private func parseSearchResults(skobblerResults: [SKSearchResult], city: String) -> [SimplePOI] {
    
    var searchResults = [SimplePOI]()
    for skobblerResult in skobblerResults {
      searchResults.append(parseSearchResult(skobblerResult, city: city))
    }
    return searchResults
  }
  
  private func parseSearchResult(skobblerResult: SKSearchResult, city: String) -> SimplePOI {
    
    let searchResult = SimplePOI()
    searchResult.name = skobblerResult.name
    
    searchResult.latitude = skobblerResult.coordinate.latitude
    searchResult.longitude = skobblerResult.coordinate.longitude
    searchResult.location = city
    searchResult.category = 180
    return searchResult
  }
  
  private func searchMapData(listLevel: SKListLevel, searchString: String, parent: UInt64) {
    let multiStepSearchObject = SKMultiStepSearchSettings()
    multiStepSearchObject.listLevel = listLevel
    multiStepSearchObject.offlinePackageCode = self.packageCode
    multiStepSearchObject.searchTerm = searchString
    multiStepSearchObject.parentIndex = parent
    
    let searcher = MultiStepSearchViewController()
    searcher.multiStepObject = multiStepSearchObject
    searcher.fireSearch()
  }
}

extension SearchService: SKSearchServiceDelegate {
  
  func searchService(searchService: SKSearchService!, didRetrieveMultiStepSearchResults searchResults: [AnyObject]!) {
    
    print("search results received")
    print(searchHandler)
    searchHandler(searchResults as! [SKSearchResult])
  }
  
  func searchServiceDidFailToRetrieveMultiStepSearchResults(searchService: SKSearchService!) {
    if !DownloadService.hasMapPackage(packageCode) {
      print("Tried to search in package not installed: " + packageCode)
    }
    else {
      print("Unknown failure with search")
    }
    
    searchRunning = false
  }
}