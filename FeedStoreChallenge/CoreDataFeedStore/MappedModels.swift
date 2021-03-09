//
//  MappedModels.swift
//  FeedStoreChallenge
//
//  Created by Edgar Hirama on 03/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

@objc(LocalCache)
public class LocalCache: NSManagedObject {

	@NSManaged public var feed: NSOrderedSet
	@NSManaged public var timestamp: Date

	public var localFeed: [LocalFeedImage] {
		feed.array.compactMap { ($0 as? CacheFeedImage)?.localFeedImage }
	}
}

@objc(CacheFeedImage)
public class CacheFeedImage: NSManagedObject {

	@NSManaged public var id: UUID
	@NSManaged public var imageDescription: String?
	@NSManaged public var location: String?
	@NSManaged public var url: URL

	public var localFeedImage: LocalFeedImage {
		LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
	}
}
