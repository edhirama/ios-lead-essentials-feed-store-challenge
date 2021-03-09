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

	@NSManaged internal var feed: NSOrderedSet
	@NSManaged internal var timestamp: Date

	internal var localFeed: [LocalFeedImage] {
		feed.array.compactMap { ($0 as? CacheFeedImage)?.localFeedImage }
	}
}

@objc(CacheFeedImage)
internal class CacheFeedImage: NSManagedObject {

	@NSManaged internal var id: UUID
	@NSManaged internal var imageDescription: String?
	@NSManaged internal var location: String?
	@NSManaged internal var url: URL

	internal var localFeedImage: LocalFeedImage {
		LocalFeedImage(id: id, description: imageDescription, location: location, url: url)
	}
}
