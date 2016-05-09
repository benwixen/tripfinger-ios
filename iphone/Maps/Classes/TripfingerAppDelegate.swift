import UIKit
import Alamofire
import CoreLocation

class MyNavigationController: UINavigationController {
  
  override func supportedInterfaceOrientations() -> UInt {
    let className = String(topViewController!.dynamicType)
    if className == "MapViewController" {
      return UInt(UIInterfaceOrientationMask.All.rawValue)
    } else {
      return UInt(UIInterfaceOrientationMask.Portrait.rawValue)
    }
  }
}

@objc public class TripfingerAppDelegate: NSObject {
  
  static var serverUrl = "https://1-3-dot-tripfinger-server.appspot.com"
  static var mode = AppMode.BETA
  static var session: Session!
  static var coordinateSet = Set<Int64>()
  static let navigationController = MyNavigationController()

  public func applicationLaunched(application: UIApplication, delegate: UIApplicationDelegate, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> UIWindow {
    
    if NSProcessInfo.processInfo().arguments.contains("TEST") {
      print("Switching to test mode")
      TripfingerAppDelegate.mode = AppMode.TEST
    }

    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.timeoutIntervalForRequest = 300 // seconds
    configuration.timeoutIntervalForResource = 60 * 60 * 48
    NetworkUtil.alamoFireManager = Alamofire.Manager(configuration: configuration)

    TripfingerAppDelegate.session = Session()

    print("didFinishLaunchingWithOptions!!")
    let window = UIWindow(frame: UIScreen.mainScreen().bounds)
    window.backgroundColor = UIColor.whiteColor()
    window.makeKeyAndVisible()
    TripfingerAppDelegate.navigationController.automaticallyAdjustsScrollViewInsets = false
    let regionController = RegionController(session: TripfingerAppDelegate.session)
    regionController.edgesForExtendedLayout = .None // offset from navigation bar
    TripfingerAppDelegate.navigationController.viewControllers = [regionController]
    window.rootViewController = TripfingerAppDelegate.navigationController

    if NSProcessInfo.processInfo().arguments.contains("OFFLINEMAP") {
      print("Installing test-map before offline-mode")
      let failure = {
        fatalError("Connection failed")
      }
      DownloadService.downloadCountry("Brunei", progressHandler: { progress in }, failure: failure) {
        print("Brunei download finished")
        regionController.loadCountryLists() // remove online countries from list
        regionController.tableView.accessibilityValue = "bruneiReady"
      }
      NetworkUtil.simulateOffline = true
    } else if NSProcessInfo.processInfo().arguments.contains("OFFLINE") {
      print("Simulating offline mode")
      NetworkUtil.simulateOffline = true
    }
    
    TripfingerAppDelegate.coordinateSet = DatabaseService.getCoordinateSet()
    print("fetched coordinateSet: ")
    print(TripfingerAppDelegate.coordinateSet)

    return window
  }
  
  public class func getPoisForArea(topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D, zoomLevel: Int) -> [TripfingerEntity] {
    
    if zoomLevel < 10 {
      return [TripfingerEntity]()
    }

    let topRight = CLLocationCoordinate2DMake(topLeft.latitude, bottomRight.longitude)
    let bottomLeft = CLLocationCoordinate2DMake(bottomRight.latitude, topLeft.longitude)
    let pois = DatabaseService.getPois(bottomLeft, topRight: topRight, zoomLevel: 15) //, category: session.currentCategory)

    var annotations = [TripfingerEntity]()

    for poi in pois {
      let annotation = TripfingerEntity(poi: poi)
      annotations.append(annotation)
    }

    print("Fetched \(annotations.count) annotations. botLeft: \(bottomLeft), topRight: \(topRight)")

    return annotations;
  }
  
  public class func getPoisForArea(topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D, category: Int) -> [TripfingerEntity] {
    
    let topRight = CLLocationCoordinate2DMake(topLeft.latitude, bottomRight.longitude)
    let bottomLeft = CLLocationCoordinate2DMake(bottomRight.latitude, topLeft.longitude)
    let pois = DatabaseService.getPois(bottomLeft, topRight: topRight, category: category)
    
    var annotations = [TripfingerEntity]()
    
    for poi in pois {
      let annotation = TripfingerEntity(poi: poi)
      annotations.append(annotation)
    }
    
    print("Searched \(annotations.count) annotations. botLeft: \(bottomLeft), topRight: \(topRight)")
    
    return annotations;
  }

  public class func getPoiById(id: Int32) -> TripfingerEntity {
    let listingId = TripfingerEntity.idMap[id]!
    let listing = DatabaseService.getListingWithId(listingId)
    let annotation = TripfingerEntity()
    annotation.name = listing?.item().name
    annotation.lat = listing!.listing.latitude
    annotation.lon = listing!.listing.longitude
    annotation.type = Int32(Listing.SubCategory(rawValue: listing!.item().subCategory)!.osmType)
    return annotation
  }

  public class func getListingById(id: Int32) -> TripfingerEntity {
    let listingId = TripfingerEntity.idMap[id]!
    let listing = DatabaseService.getListingWithId(listingId)!
    session.currentListing = listing
    return TripfingerEntity(listing: listing)
  }
  
  public class func getListingByCoordinate(coord: CLLocationCoordinate2D) -> TripfingerEntity {
    let listing = DatabaseService.getListingByCoordinate(coord)
    session.currentListing = listing
    let entity = TripfingerEntity(listing: listing!)
    entity.putInIdMap(listing!.item().id)
    return entity
  }

  public class func coordinateToInt(coord: CLLocationCoordinate2D) -> Int64 {
    let latInt = Int64((coord.latitude * 1000000) + 0.5)
    let lonInt = Int64((coord.longitude * 1000000) + 0.5)
    let sign: Int64
    if latInt >= 0 && lonInt >= 0 {
      sign = 1
    } else if latInt >= 0 {
      sign = 2
    } else if lonInt >= 0 {
      sign = 3
    } else {
      sign = 4
    }
    return (sign * 100000000000000000) + (abs(latInt) * 100000000) + abs(lonInt)
  }
  
  public class func coordinateExists(coord: CLLocationCoordinate2D) -> Bool {
    let intCoord = coordinateToInt(coord)
    let exists = TripfingerAppDelegate.coordinateSet.contains(intCoord)
    return exists
  }
  
  public class func nameToCategoryId(name: String) -> Int {
    let trimmedString = name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    if let cat = Listing.Category.entityMap[trimmedString] {
      print("returning category with entName: \(cat.entityName)")
      return cat.rawValue
    } else {
      return 0
    }
  }
  
  static var viewControllers = [UIViewController]()
    
  public class func displayPlacePage(views: [UIView]) {
    let searchDelegate = TripfingerAppDelegate.navigationController.viewControllers[0] as! RegionController
    let detailController = DetailController(session: session, searchDelegate: searchDelegate, placePageViews: views)
    if viewControllers.count > 0 {
      let newViewControllers = TripfingerAppDelegate.viewControllers + [detailController]
      TripfingerAppDelegate.navigationController.setViewControllers(newViewControllers, animated: true)
      TripfingerAppDelegate.viewControllers = [UIViewController]()
    } else {
      TripfingerAppDelegate.navigationController.pushViewController(detailController, animated: true)
    }
  }
  
  class func navigateToLicense() { // for listings from map
    let licenseController: UIViewController
    licenseController = LicenseController(textItem: session.currentListing.item(), imageItem: session.currentListing.item())
    licenseController.edgesForExtendedLayout = .None // offset from navigation bar
    TripfingerAppDelegate.navigationController.pushViewController(licenseController, animated: true)
  }

  class func bookmarkAdded() {
    DatabaseService.saveLike(GuideListingNotes.LikedState.LIKED, listing: session.currentListing)
  }
  
  class func bookmarkRemoved() {
    DatabaseService.saveLike(GuideListingNotes.LikedState.SWIPED_LEFT, listing: session.currentListing)
  }
  
//  public class func getImageViewCell() -> UIView {
//    
//  }

  enum AppMode {
    case TEST
    case BETA
    case RELEASE
  }
}