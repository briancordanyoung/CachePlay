//
//  CachePlayTests.swift
//  CachePlayTests
//
//  Created by Brian Cordan Young on 1/28/18.
//  Copyright © 2018 BrianCordanYoung. All rights reserved.
//

import XCTest
@testable import CachePlay

class KeyedCacheTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testMaximumItemsAndOrder() {
    var cache = KeyedCache<Double,String>(itemLimit: 5)
    cache.add(item: 123.123, withKey: "A")
    cache.add(item: 234.123, withKey: "B")
    cache.add(item: 345.123, withKey: "C")
    cache.add(item: 456.123, withKey: "D")
    cache.add(item: 567.123, withKey: "E")
    cache.add(item: 678.123, withKey: "F")
    cache.add(item: 789.123, withKey: "G")
    
    let keys = cache.allKeys
    XCTAssert(keys.count == 5)
    XCTAssert(keys[0] == "G")
    XCTAssert(keys[1] == "F")
    XCTAssert(keys[2] == "E")
    XCTAssert(keys[3] == "D")
    XCTAssert(keys[4] == "C")
    
    let items = cache.allItems
    XCTAssert(items.count == 5)
    XCTAssert(items[0] == 789.123)
    XCTAssert(items[1] == 678.123)
    XCTAssert(items[2] == 567.123)
    XCTAssert(items[3] == 456.123)
    XCTAssert(items[4] == 345.123)
  
    for key in ["A","B"] {
      let item = cache.itemFor(key: key)
      XCTAssert(item == .none)
    }
  }
  
  func testOrderOfAccess() {
    var cache = KeyedCache<Double,String>(itemLimit: 5)
    cache.add(item: 123.123, withKey: "A")
    cache.add(item: 234.123, withKey: "B")
    cache.add(item: 345.123, withKey: "C")
    cache.add(item: 456.123, withKey: "D")
    cache.add(item: 567.123, withKey: "E")
    cache.add(item: 678.123, withKey: "F")
    cache.add(item: 789.123, withKey: "G")
    
    var item = cache.itemFor(key: "D")
    item = cache.itemFor(key: "F")
    XCTAssert(item == 678.123)
    
    let keys = cache.allKeys
    XCTAssert(keys.count == 5)
    XCTAssert(keys[0] == "F")
    XCTAssert(keys[1] == "D")
    XCTAssert(keys[2] == "G")
    XCTAssert(keys[3] == "E")
    XCTAssert(keys[4] == "C")
    
    for key in ["A","B"] {
      let item = cache.itemFor(key: key)
      XCTAssert(item == .none)
    }
  }
  
  
  func testOrderOfAccessUnderLimit() {
    var cache = KeyedCache<Double,String>(itemLimit: 50)
    cache.add(item: 123.123, withKey: "A")
    cache.add(item: 234.123, withKey: "B")
    cache.add(item: 345.123, withKey: "C")
    cache.add(item: 456.123, withKey: "D")
    cache.add(item: 567.123, withKey: "E")
    cache.add(item: 678.123, withKey: "F")
    cache.add(item: 789.123, withKey: "G")
    
    var item = cache.itemFor(key: "D")
    item = cache.itemFor(key: "F")
    XCTAssert(item == 678.123)
    
    let keys = cache.allKeys
    XCTAssert(keys.count == 7)
    XCTAssert(keys[0] == "F")
    XCTAssert(keys[1] == "D")
    XCTAssert(keys[2] == "G")
    XCTAssert(keys[3] == "E")
    XCTAssert(keys[4] == "C")
    XCTAssert(keys[5] == "B")
    XCTAssert(keys[6] == "A")
  }
  
  func testOrderOfAccessStupidLimit() {
    var cache = KeyedCache<Double,String>(itemLimit: 1)
    cache.add(item: 123.123, withKey: "A")
    cache.add(item: 234.123, withKey: "B")
    cache.add(item: 345.123, withKey: "C")
    cache.add(item: 456.123, withKey: "D")
    cache.add(item: 567.123, withKey: "E")
    cache.add(item: 678.123, withKey: "F")
    cache.add(item: 789.123, withKey: "G")
    
    let item = cache.itemFor(key: "G")
    XCTAssert(item == 789.123)
    
    let keys = cache.allKeys
    XCTAssert(keys.count == 1)
    XCTAssert(keys[0] == "G")

    for key in ["A","B","C","D","E","F"] {
      let item = cache.itemFor(key: key)
        XCTAssert(item == .none)
    }
  }


}

