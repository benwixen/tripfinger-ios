import Foundation
import StoreKit
import KeychainSwift
import Firebase

public typealias ProductIdentifier = String
public typealias ProductsRequestCompletionHandler = (success: Bool, products: [SKProduct]?) -> ()

class PurchasesService: NSObject {
  
  static let TFPurchaseNotification = "TFPurchaseNotification"
  static let TFPurchaseFailedNotification = "TFPurchaseFailedNotification"
  
  static let sharedInstance = PurchasesService()
  static let keychainKey = "tfPurchases"

  private var productIdentifiers: [String: ProductIdentifier]?
  private var purchasedProductIdentifiers: Set<ProductIdentifier>?
  private var products: [String: SKProduct]?
  private var productsRequest: SKProductsRequest?
  
  private var dispatchGroup: dispatch_group_t!
  
  private func initPurchasing(regionUuid: String, callback: (product: SKProduct, purchased: Bool) -> ()) {
    print("Initializing PurchasesService")
    SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    dispatchGroup = dispatch_group_create()
    dispatch_group_enter(dispatchGroup)
    loadPurchasesFromKeychain(dispatchGroup)
    dispatch_group_enter(dispatchGroup)
    fetchProductIdentifiers()
    dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) {
      let productId = self.productIdentifiers![regionUuid]!
      print("Purchases:")
      print(self.purchasedProductIdentifiers)
      let purchased = self.purchasedProductIdentifiers!.contains(productId)
      let product = self.products![productId]!
      callback(product: product, purchased: purchased)
    }
  }
  
  private func fetchProductIdentifiers() {
    let url = TripfingerAppDelegate.serverUrl + "/products"
    NetworkUtil.getJsonFromUrl(url, failure: { fatalError("error xu67") }) { json in
      self.productIdentifiers = [String: ProductIdentifier]()
      for productJson in json.array! {
        let regionUuid = productJson["regionUuid"].string!
        self.productIdentifiers![regionUuid] = productJson["itunesProductId"].string!
      }
      self.fetchItunesProducts()
    }
  }
  
  private func fetchItunesProducts() {
    productsRequest?.cancel()
    print("trying to get info for productidentifiers:")
    print(Set(productIdentifiers!.values))
    productsRequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers!.values))
    productsRequest!.delegate = self
    productsRequest!.start()
  }
  
  private func loadPurchasesFromKeychain(dispatchGroup: dispatch_group_t) {
    let keychain = KeychainSwift()
    guard let purchasesString = keychain.get(PurchasesService.keychainKey) else {
      SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
      return
    }
    let purchasesArr = purchasesString.characters.split{$0 == ","}.map(String.init)
    purchasedProductIdentifiers = Set<ProductIdentifier>()
    for purchase in purchasesArr {
      purchasedProductIdentifiers!.insert(purchase)
    }
    dispatch_group_leave(dispatchGroup)
  }
  
  class func purchaseCountry(country: Region, downloadStarted: () -> ()) {
    getFirstPurchase(UniqueIdentifierService.uniqueIdentifier()) { firstCountryUuid in
      guard let firstCountryUuid = firstCountryUuid else {
        openFirstCountryController(country, downloadStarted: downloadStarted)
        return
      }
      if firstCountryUuid == country.getId() {
        proceedWithDownload(country)
        downloadStarted()
      } else {
        openPurchaseController(country, downloadStarted: downloadStarted)
      }
    }
  }
  
  private class func openFirstCountryController(country: Region, downloadStarted: () -> ()) {
    let firstCountryController = FirstCountryDownloadView(country: country, cancelHandler: downloadStarted) {
      makeCountryFirst(country) {
        FIRAnalytics.logEventWithName("first_download", parameters: [
          "country": country.getName()
          ])
        TripfingerAppDelegate.navigationController.dismissViewControllerAnimated(true, completion: nil)
        proceedWithDownload(country)
        downloadStarted()
      }
    }
    dispatch_async(dispatch_get_main_queue()) {
      let modalNav = UINavigationController()
      modalNav.viewControllers = [firstCountryController]
      TripfingerAppDelegate.navigationController.presentViewController(modalNav, animated: true, completion: nil)
      TripfingerAppDelegate.styleNavigationBar(modalNav.navigationBar)
    }
  }
  
  class func makeCountryFirst(country: Region, complete: () -> ()) {
    let deviceUuid = UniqueIdentifierService.uniqueIdentifier()
    let url = TripfingerAppDelegate.serverUrl + "/products/first_country/\(deviceUuid)/\(country.getId())"
    NetworkUtil.getJsonFromPost(url, body: "543gfdg3t23fevwef3tg", success: { json in
      complete()
      }, failure: { fatalError("fail fesv3") })
  }
  
  private class func openPurchaseController(country: Region, downloadStarted: () -> ()) {
    print("purchaseController")
    let purchaseInstance = PurchasesService()
    purchaseInstance.initPurchasing(country.getId()) { product, purchased in
      if purchased {
        proceedWithDownload(country, receipt: "XZBDSF252-FA23SDFS-SFSGSZZ67")
        downloadStarted()
      } else {
        let purchaseController = PurchaseCountryVC(country: country, product: product, cancelHandler: downloadStarted) {
          TripfingerAppDelegate.navigationController.dismissViewControllerAnimated(true, completion: nil)
          proceedWithDownload(country, receipt: "XZBDSF252-FA23SDFS-SFSGSZZ67")
          purchaseInstance.dispatchGroup = nil // mainly to keep instance alive
          downloadStarted()
        }
        dispatch_async(dispatch_get_main_queue()) {
          let modalNav = UINavigationController()
          TripfingerAppDelegate.styleNavigationBar(modalNav.navigationBar)
          modalNav.viewControllers = [purchaseController]
          TripfingerAppDelegate.navigationController.presentViewController(modalNav, animated: true, completion: nil)
        }
      }
    }
  }
  
  class func proceedWithDownload(country: Region, receipt: String? = nil) {
    let mwmRegionId = country.mwmRegionId ?? country.getName()
    DownloadService.downloadCountry(mwmRegionId, receipt: receipt, progressHandler: {prog in
      MapsAppDelegateWrapper.updateDownloadProgress(prog, forMwmRegion: mwmRegionId)
    }, failure: {fatalError("error pba78")}) {
      MapsAppDelegateWrapper.updateDownloadState(mwmRegionId)
    }
  }

  private class func getFirstPurchase(deviceUuid: String, handler: String? -> ()) {
    let url = TripfingerAppDelegate.serverUrl + "/products/first_country/\(deviceUuid)"
    let failure = {
      fatalError("Couldn't get the purchase thang")
    }
    NetworkUtil.getJsonFromUrl(url, failure: failure) { json in
      print(json)
      let countryUuid = json["productLine"]["regionUuid"].string
      handler(countryUuid)
    }
  }
}

extension PurchasesService: SKProductsRequestDelegate {
  
  func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
    print("Loaded list of products...")
    self.products = [String: SKProduct]()
    for product in response.products {
      self.products![product.productIdentifier] = product
    }
    productsRequest = nil
    
    for (_, p) in self.products! {
      print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
    }
    dispatch_group_leave(dispatchGroup)
  }
  
  func request(request: SKRequest, didFailWithError error: NSError) {
    print("Failed to load list of products.")
    print("Error: \(error.localizedDescription)")
    productsRequest = nil
    fatalError("error 9x67")
  }
}

extension PurchasesService: SKPaymentTransactionObserver {
  
  func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      print("handling transaction: \(transaction.transactionState)")
      switch  transaction.transactionState {
      case .Purchased:
        completeTransaction(transaction)
      case .Failed:
        failedTransaction(transaction)
      case .Restored:
        break
      case .Deferred:
        break
      case .Purchasing:
        break
      }
    }
  }
  
  private func completeTransaction(transaction: SKPaymentTransaction) {
    print("completeTransaction...")
    let keychain = KeychainSwift()
    purchasedProductIdentifiers!.insert(transaction.payment.productIdentifier)
    keychain.set(purchasedProductIdentifiers!.joinWithSeparator(","), forKey: PurchasesService.keychainKey)

    deliverPurchaseNotificationForIdentifier(transaction.payment.productIdentifier)
    SKPaymentQueue.defaultQueue().finishTransaction(transaction)
  }
  
  private func failedTransaction(transaction: SKPaymentTransaction) {
    print("failedTransaction...")
    if transaction.error!.code != SKErrorCode.PaymentCancelled.rawValue {
      print("Transaction Error: \(transaction.error?.localizedDescription)")
      deliverPurchaseFailedNotificationForIdentifier(transaction.originalTransaction?.payment.productIdentifier)
    }
    
    SKPaymentQueue.defaultQueue().finishTransaction(transaction)
  }
  
  func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
    print("paymentQueueRestoreCompletedTransactionsFinished")
    purchasedProductIdentifiers = Set<ProductIdentifier>()
    for transaction in queue.transactions {
      if let productIdentifier = transaction.originalTransaction?.payment.productIdentifier {
        purchasedProductIdentifiers!.insert(productIdentifier)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
      }
    }
    let keychain = KeychainSwift()
    keychain.set(purchasedProductIdentifiers!.joinWithSeparator(","), forKey: PurchasesService.keychainKey)
    dispatch_group_leave(dispatchGroup)
  }
  
  private func deliverPurchaseNotificationForIdentifier(identifier: String?) {
    guard let identifier = identifier else { return }
    
    NSNotificationCenter.defaultCenter().postNotificationName(PurchasesService.TFPurchaseNotification, object: identifier)
  }
  
  private func deliverPurchaseFailedNotificationForIdentifier(identifier: String?) {
    guard let identifier = identifier else { return }
    
    NSNotificationCenter.defaultCenter().postNotificationName(PurchasesService.TFPurchaseFailedNotification, object: identifier)
  }

}