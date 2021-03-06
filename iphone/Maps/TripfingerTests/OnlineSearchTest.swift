import UIKit
import XCTest
@testable import Tripfinger

class OnlineSearchTest: XCTestCase {
  
  override func setUp() {
    super.setUp()
    TripfingerAppDelegate.mode = .TEST
    continueAfterFailure = false
  }
  
  override func tearDown() {
    super.tearDown()
  }

  func testOnlineSearch() {
    let readyExpectation = expectationWithDescription("ready")
    
    OnlineSearch.search("temburong") {
      searchResults in
      
      XCTAssertEqual(1, searchResults.count)
      readyExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(15, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }

  func testOnlineSearchMultipleTerms() {
    let readyExpectation = expectationWithDescription("ready")
    
    OnlineSearch.search("boulevard dixmude") { searchResults in
      readyExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(15, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
}