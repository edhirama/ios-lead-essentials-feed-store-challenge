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
internal class LocalCache: NSManagedObject {

	@NSManaged public var feed: NSOrderedSet
	@NSManaged public var timestamp: Date

	internal var localFeed: [LocalFeedImage] {
		feed.array.compactMap { ($0 as? CacheFeedImage)?.localFeedImage }
	}
}

@objc(CacheFeedImage)
internal class CacheFeedImage: NSManagedObject {

	@NSManaged public var id: UUID
	@NSManaged public var imageDescription: String?
	@NSManaged public var location: String?
	@NSManaged public var url: URL

	internal var localFeedImage: LocalFeedImage {
		LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
	}
}
