//
//  XCTestCase+Helpers.swift
//  Tests
//
//  Created by Edgar Hirama on 09/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest

extension XCTestCase {
	func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, file: file, line: line)
		}
	}
}
