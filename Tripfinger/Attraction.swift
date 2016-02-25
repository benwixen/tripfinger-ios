import Foundation
import RealmSwift

class Attraction: Object {
  
  // composition (instead of inheritance - for Realm-purposes)
  dynamic var listing: GuideListing!
  
  dynamic var price: String?
  dynamic var openingHours: String?
  dynamic var directions: String?
  
  func categoryName(currentRegion: Region?) -> String {
    return Category(rawValue: listing.item.category)!.entityName(currentRegion)
  }
  
  func item() -> GuideItem {
    return listing.item
  }
  
  enum Category: Int {
    case ATTRACTIONS = 200
//    case EXPLORE_CITY = 210
//    case ACTIVITY_HIKE_DAYTRIP = 220
    case TRANSPORTATION = 230
    case ACCOMODATION = 240
    case FOOD_OR_DRINK = 250
    case SHOPPING = 260
    case INFORMATION = 270
    
    var entityName: String {
      switch self {
      case .ATTRACTIONS:
        return "Attractions"
      case .TRANSPORTATION:
        return "Transportation"
      case .ACCOMODATION:
        return "Accomodation"
      case .FOOD_OR_DRINK:
        return "Food and drinks"
      case .SHOPPING:
        return "Shopping"
      case .INFORMATION:
        return "Information"
      }
    }
    
    func entityName(currentRegion: Region?) -> String {
      if entityName == "Explore the city" {
        if currentRegion == nil {
          return "Explore the world"
        }
        switch currentRegion!.listing.item.category {
        case Region.Category.CONTINENT.rawValue:
          return "Explore the continent"
        case Region.Category.COUNTRY.rawValue:
          return "Explore the country"
        default:
          return entityName
        }
      }
      return entityName
    }
    
    static let allValues = [ATTRACTIONS, TRANSPORTATION, ACCOMODATION,
      FOOD_OR_DRINK, SHOPPING, INFORMATION]
  }  
}
