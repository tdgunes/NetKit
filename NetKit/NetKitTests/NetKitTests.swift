//
//  NetKitTests.swift
//  NetKitTests
//
//  Created by Taha Doğan Güneş on 10/06/15.
//  Copyright (c) 2015 Taha Doğan Güneş. All rights reserved.
//

import UIKit
import XCTest

class NetKitTests: XCTestCase {
    var nkit: NetKit?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        nkit = NetKit(baseURL: "http://tdgunes.org")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        
        super.tearDown()
    }

    func testGETGithub(){
        let url = "https://api.github.com/gists/5d8d25e603fcac6bb65f"
        nkit!.baseURL = url
        nkit!.get(completionHandler: {
            response in
                XCTAssert(HTTPStatus.OK == response.status, "Status Check")
                if let id = response.json!["id"].asString {
                    XCTAssert(id == "5d8d25e603fcac6bb65f", "ID Check")
                    return
                }
            
            XCTAssert(false, "Unexpected response!")
        })

    }
    
    func testGet() {
        nkit!.get()
    }

    func testPost() {
        nkit!.post()
    }
    
    func testPut() {
        nkit!.put()
    }
    
    func testDelete() {
        nkit!.delete()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
