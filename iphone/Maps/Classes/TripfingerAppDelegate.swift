import UIKit
import Alamofire
import CoreLocation
import Firebase
import FirebaseInstanceID

@objc public class TripfingerAppDelegate: NSObject {
  
  static let sharedInstance = TripfingerAppDelegate()
  static var serverUrl = "https://tripfinger-server.appspot.com/"
  static var mode = AppMode.RELEASE
  static var coordinateSet = Set<Int64>()
  static let navigationController = TripfingerNavigationController()
  var openUrl = ""

  class func applicationLaunched(application: UIApplication, delegate: UIApplicationDelegate, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> UIWindow {
    
    NSUserDefaults.standardUserDefaults().registerDefaults(["statisticsEnabled": true])
    
    DatabaseMigrations.migrateVersion1()
    NotificationsService.applicationLaunched(application, delegate: delegate, didFinishLaunchingWithOptions: launchOptions)
    AnalyticsService.applicationLaunched(application, delegate: delegate, didFinishLaunchingWithOptions: launchOptions)
    
    TripfingerAppDelegate.styleNavigationBar(TripfingerAppDelegate.navigationController.navigationBar)

    let installedFromAppStore = !(NSBundle.mainBundle().appStoreReceiptURL?.lastPathComponent == "sandboxReceipt")
    let launchArgs = NSProcessInfo.processInfo().arguments
    if launchArgs.contains("TEST") {
      mode = .TEST
    } else if !installedFromAppStore {
      let testMode = NSUserDefaults.standardUserDefaults().boolForKey("enableTestMode")
      if testMode {
        mode = .DRAFT
      } else {
        mode = .BETA
      }
    }
    AnalyticsService.logAppMode(mode)

    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    configuration.timeoutIntervalForRequest = 300 // seconds
    configuration.timeoutIntervalForResource = 60 * 60 * 48
    NetworkUtil.alamoFireManager = Alamofire.Manager(configuration: configuration)

    let taploggingEnabled = mode == .TEST
    let window = TapLoggingWindow(tapLoggingEnabled: taploggingEnabled, frame: UIScreen.mainScreen().bounds)
    window.backgroundColor = UIColor.whiteColor()
    window.makeKeyAndVisible()
    TripfingerAppDelegate.navigationController.automaticallyAdjustsScrollViewInsets = false
    let regionController = CountryListController()
    TripfingerAppDelegate.navigationController.viewControllers = [regionController]
    window.rootViewController = TripfingerAppDelegate.navigationController

    if NSProcessInfo.processInfo().arguments.contains("OFFLINEMAP") {
      let failure = {
        assertionFailure("Connection failed")
      }
      ContentService.getCountryWithName("Brunei", failure: failure) { brunei in
        PurchasesService.makeCountryFirst(brunei, connectionError: failure) {
          DownloadService.downloadCountry("Brunei", progressHandler: { progress in }, failure: failure) {
            regionController.tableView.accessibilityValue = "bruneiReady"
          }
        }
      }
      NetworkUtil.simulateOffline = true
    } else if NSProcessInfo.processInfo().arguments.contains("OFFLINE") {
      print("Simulating offline mode")
      NetworkUtil.simulateOffline = true
    } else {
      DownloadService.resumeDownloads()      
    }
    
    TripfingerAppDelegate.coordinateSet = DatabaseService.getCoordinateSet()
    print("fetched coordinateSet: ")
    print(TripfingerAppDelegate.coordinateSet)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(repopulateCoordinateSet), name: DatabaseService.TFCountrySavedNotification, object: nil)

    return window
  }
  
  class func applicationDidBecomeActive(application: UIApplication) {
    NotificationsService.applicationDidBecomeActive(application)
    AnalyticsService.applicationDidBecomeActive(application)
  }
  
  class func application(application: UIApplication, openURL url: NSURL, sourceApplication: NSString, annotation: AnyObject) -> Bool {
    return AnalyticsService.application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
  }
  
  class func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject],
                   fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
    NotificationsService.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
  
  class func applicationDidEnterBackground(application: UIApplication) {
    NotificationsService.applicationDidEnterBackground(application)
  }
  
  class func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
    NotificationsService.application(application, didRegisterUserNotificationSettings: notificationSettings)
  }
  
  class func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
    NotificationsService.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  class func repopulateCoordinateSet() {
    print("repopulating coordinate set")
    coordinateSet = DatabaseService.getCoordinateSet()
  }
  
  class func styleNavigationBar(bar: UINavigationBar) {
    let colorImage = UIImage(withColor: UIColor.primary(), frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 64))
    bar.setBackgroundImage(colorImage, forBarMetrics: .Default)
    bar.translucent = true
    bar.tintColor = UIColor.white()
  }

  
  public class func getPoisForArea(topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D, zoomLevel: Int) -> [TripfingerEntity] {
    
    if zoomLevel < 10 {
      return [TripfingerEntity]()
    }

    let topRight = CLLocationCoordinate2DMake(topLeft.latitude, bottomRight.longitude)
    let bottomLeft = CLLocationCoordinate2DMake(bottomRight.latitude, topLeft.longitude)
    let listings = DatabaseService.getPois(bottomLeft, topRight: topRight, zoomLevel: 15)

    var entities = [TripfingerEntity]()
    for listing in listings {
      let entity = TripfingerEntity(listing: listing)
      entities.append(entity)
    }

    print("Fetched \(entities.count) entities. botLeft: \(bottomLeft), topRight: \(topRight)")
    return entities;
  }
  
  public class func getPoisForArea(topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D, category: Int) -> [TripfingerEntity] {
    
    let topRight = CLLocationCoordinate2DMake(topLeft.latitude, bottomRight.longitude)
    let bottomLeft = CLLocationCoordinate2DMake(bottomRight.latitude, topLeft.longitude)
    let listings = DatabaseService.getPois(bottomLeft, topRight: topRight, category: category)
    
    var entities = [TripfingerEntity]()
    for listing in listings {
      let entity = TripfingerEntity(listing: listing)
      entities.append(entity)
    }
    
    print("Cat-fetched \(entities.count) entities. botLeft: \(bottomLeft), topRight: \(topRight)")    
    return entities;
  }
  
  public class func poiSearch(query: String, includeRegions: Bool) -> [TripfingerEntity] {
    let semaphore = dispatch_semaphore_create(0)
    let searchService = SearchService()
    var entities = [TripfingerEntity]()
    searchService.search(query) { results in
      for poi in results {
        if includeRegions || Listing.Category(rawValue: poi.category) != nil {
          let entity = TripfingerEntity(poi: poi)
          entities.append(entity)
        }
      }
      dispatch_semaphore_signal(semaphore)
    }
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    
    return entities
  }

  public class func getOfflineListingById(listingId: String) -> TripfingerEntity {
    let listing = DatabaseService.getListingWithId(listingId)!
    return TripfingerEntity(listing: listing)
  }

  public class func getOnlineListingById(listingId: String) -> TripfingerEntity {
    let semaphore = dispatch_semaphore_create(0)
    var retListing: Listing! = nil
    ContentService.getListingWithId(listingId, failure: connectionError, withNotes: false) { listing in
      retListing = listing
      dispatch_semaphore_signal(semaphore)
    }
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    return TripfingerEntity(listing: retListing)
  }
  
  public class func isListingOffline(listingId: String) -> Bool {
    return DatabaseService.getListingWithId(listingId) != nil
  }

  
  public class func getListingByCoordinate(coord: CLLocationCoordinate2D) -> TripfingerEntity {
    let listing = DatabaseService.getListingByCoordinate(coord)!
    let entity = TripfingerEntity(listing: listing)
    return entity
  }

  public class func coordinateToInt(coord: CLLocationCoordinate2D) -> Int64 {
    let latInt = Int64(abs(coord.latitude * 1000000) + 0.5)
    let lonInt = Int64(abs(coord.longitude * 1000000) + 0.5)
    let sign: Int64
    if coord.latitude >= 0 && coord.longitude >= 0 {
      sign = 1
    } else if coord.latitude >= 0 {
      sign = 2
    } else if coord.longitude >= 0 {
      sign = 3
    } else {
      sign = 4
    }
    return (sign * 100000000000000000) + (latInt * 100000000) + lonInt
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
    
  public class func displayPlacePage(views: [UIView], entity: TripfingerEntity, countryMwmId: String) {
    let detailController = DetailController(entity: entity, countryDownloadId: countryMwmId, placePageViews: views)
    if viewControllers.count > 0 {
      let newViewControllers = TripfingerAppDelegate.viewControllers + [detailController]
      TripfingerAppDelegate.navigationController.setViewControllers(newViewControllers, animated: true)
      TripfingerAppDelegate.viewControllers = [UIViewController]()
    } else {
      TripfingerAppDelegate.navigationController.pushViewController(detailController, animated: true)
    }
  }

  class func bookmarkAdded(listingId: String) {
    DatabaseService.saveLikeInTf(GuideListingNotes.LikedState.LIKED, listingId: listingId)
  }
  
  class func bookmarkRemoved(listingId: String) {
    DatabaseService.saveLikeInTf(GuideListingNotes.LikedState.SWIPED_LEFT, listingId: listingId)
  }

  class func selectedSearchResult(searchResult: TripfingerEntity, failure: () -> (), stopSpinner: () -> ()) {
    TripfingerAppDelegate.navigationController.navigationBarHidden = false
    if searchResult.isListing() {
      navigationController.jumpToListingWithId(searchResult.tripfingerId, failure: failure, finishedHandler: stopSpinner)
    } else {
      navigationController.jumpToRegionWithId(searchResult.tripfingerId, failure: failure, finishedHandler: stopSpinner)
    }
  }
  
  
  class func isCountryDownloaded(countryName: String) -> Bool {
    return DownloadService.isCountryDownloaded(countryName)
  }
  
  // TODO: Add downloading-status
  class func downloadStatus(mwmCountryId: String) -> Int {
    
    var foundCountry = false
    let countryListController = TripfingerAppDelegate.navigationController.viewControllers[0] as! CountryListController
    for (_, countryList) in countryListController.countryLists {
      for country in countryList {
        if country.getDownloadId() == mwmCountryId {
          foundCountry = true
        }
      }
    }
    if !foundCountry {
      return 0
    }
    
    if DownloadService.isCountryDownloading(mwmCountryId) {
      return 1
    } else if DownloadService.isCountryDownloaded(mwmCountryId) {
      return 5
    } else { // NotDownloaded
      return 6
    }
  }
  
  class func countrySize(mwmCountryId: String) -> Int64 {
    let countryListController = TripfingerAppDelegate.navigationController.viewControllers[0] as! CountryListController
    for (_, countryList) in countryListController.countryLists {
      for country in countryList {
        if country.getDownloadId() == mwmCountryId {
          return country.getSizeInBytes()
        }
      }
    }
    LogUtils.assertionFailAndRemoteLog("Did not find size for country: \(mwmCountryId)")
    return 0
  }

  class func purchaseCountry(mwmCountryId: String, downloadStarted: () -> ()) {
    TripfingerAppDelegate.navigationController.viewControllers.last!.showLoadingHud()
    ContentService.getCountryWithName(mwmCountryId, failure: connectionError) { region in
      PurchasesService.purchaseCountry(region, connectionError: connectionError) {
        dispatch_async(dispatch_get_main_queue()) {
          TripfingerAppDelegate.navigationController.viewControllers.last!.hideHuds()
          downloadStarted()
        }
      }
    }
  }

  class func updateCountry(mwmCountryId: String, downloadStarted: () -> ()) {
    TripfingerAppDelegate.navigationController.viewControllers.last!.showLoadingHud()
    let country = DatabaseService.getCountryWithMwmId(mwmCountryId)!
    PurchasesService.getFirstPurchase(UniqueIdentifierService.uniqueIdentifier(), connectionError: connectionError) { firstCountryUuid in
      if firstCountryUuid == country.getId() {
        PurchasesService.proceedWithDownload(country, connectionError: connectionError)
      } else {
        PurchasesService.proceedWithDownload(country, receipt: "XZBDSF252-FA23SDFS-SFSGSZZ67", connectionError: connectionError)
      }
      dispatch_async(dispatch_get_main_queue()) {
        TripfingerAppDelegate.navigationController.viewControllers.last!.hideHuds()
        downloadStarted()
      }
    }
  }
  
  class func cancelDownload(mwmRegionId: String) {
    DownloadService.cancelDownload(mwmRegionId)
  }

  class func deleteCountry(mwmCountryId: String) {
    let region = DatabaseService.getCountryWithMwmId(mwmCountryId)!
    DownloadService.deleteCountry(region.getName())
  }
  
  private class func connectionError() {
    TripfingerAppDelegate.navigationController.viewControllers.last!.showErrorHud()
  }
  
  class func isReleaseMode() -> Bool {
    return mode == .RELEASE
  }
  
  class func getDraftMode() -> Bool {
    return mode == .DRAFT
  }
  
  class func setDraftMode(draftMode: Bool) {
    NSUserDefaults.standardUserDefaults().setBool(draftMode, forKey: "enableTestMode")
    if draftMode {
      mode = .DRAFT
    } else {
      mode = .BETA
    }
  }
  
  class func setStatisticsEnabled(enabled: Bool) {
    NSUserDefaults.standardUserDefaults().setBool(enabled, forKey: "statisticsEnabled")
    NSUserDefaults.standardUserDefaults().synchronize()
    FIRAnalyticsConfiguration.sharedInstance().setAnalyticsCollectionEnabled(enabled)
    AnalyticsService.disabled = !enabled
  }
  
  enum AppMode {
    case TEST
    case DRAFT
    case BETA
    case RELEASE
  }
}

extension TripfingerAppDelegate: UIAlertViewDelegate {
  
  public func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
    if buttonIndex == 1 {
      UIApplication.sharedApplication().openURL(NSURL(string: openUrl)!)
   }
  }
}