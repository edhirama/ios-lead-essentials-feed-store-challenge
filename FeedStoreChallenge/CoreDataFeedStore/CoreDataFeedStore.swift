//
//  CoreDataFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Edgar Hirama on 08/03/21.
//  Copyright © 2021 Essential Developer. All rights reserved.
//

import CoreData

public class CoreDataFeedStore: FeedStore {

	enum CoreDataError: Error {
		case unableToFindModel
		case unableToLoad(Error)
	}

	private static let resourceName: String = "FeedStore"

	private let persistentContainer: NSPersistentContainer
	private let context: NSManagedObjectContext

	public init(storeURL: URL) throws {
		self.persistentContainer = try CoreDataFeedStore.loadPersistendContainer(storeURL: storeURL)
		self.context = persistentContainer.newBackgroundContext()
	}

	private static func loadPersistendContainer(storeURL: URL) throws -> NSPersistentContainer {
		let bundle = Bundle(for: CoreDataFeedStore.self)
		guard let bundleURL = bundle.url(forResource: CoreDataFeedStore.resourceName, withExtension: "momd"),
			  let model = NSManagedObjectModel(contentsOf: bundleURL) else { throw CoreDataError.unableToFindModel }

		let container = NSPersistentContainer(name: CoreDataFeedStore.resourceName, managedObjectModel: model)
		let description = NSPersistentStoreDescription(url: storeURL)
		container.persistentStoreDescriptions = [description]

		var loadError: Error?
		container.loadPersistentStores { _, error in
			loadError = error
		}
		if let error = loadError {
			throw CoreDataError.unableToLoad(error)
		}
		return container
	}

	private func deleteCurrentCacheIfNeeded(in context: NSManagedObjectContext) {
		let fetchRequest: NSFetchRequest<LocalCache> = NSFetchRequest(entityName: LocalCache.className())
		if let fetchResult = try? context.fetch(fetchRequest), let existingFeed = fetchResult.first {
			context.delete(existingFeed)
		}
	}
}

extension CoreDataFeedStore {

	public func retrieve(completion: @escaping RetrievalCompletion) {
		let managedContext = context
		context.perform {
			do {
				let fetchRequest = NSFetchRequest<LocalCache>(entityName: "LocalCache")

				let result = try managedContext.fetch(fetchRequest)
				if let cacheResult = result.first {
					completion(.found(feed: cacheResult.localFeed , timestamp: cacheResult.timestamp))
				} else {
					completion(.empty)
				}
			} catch {
				completion(.failure(error))
			}
		}
	}
}

extension CoreDataFeedStore {

	public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		let managedContext = context
		context.perform {
			do {
				self.deleteCurrentCacheIfNeeded(in: managedContext)
				try managedContext.save()

				completion(nil)
			} catch {
				completion(error)
			}
		}
	}
}

extension CoreDataFeedStore {

	public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let managedContext = context
		context.perform {
			do {
				self.deleteCurrentCacheIfNeeded(in: managedContext)
				self.createNewCachedFeed(feed, timestamp: timestamp, in: managedContext)

				try managedContext.save()

				completion(nil)
			} catch {
				completion(error)
			}
		}
	}

	private func createNewCachedFeed(_ feed: [LocalFeedImage], timestamp: Date, in context: NSManagedObjectContext) {
		var cacheFeed = [CacheFeedImage]()
		feed.forEach { cacheFeed.append(self.entity(for: $0, withManagedContext: context))}

		let localCache = LocalCache(context: context)
		localCache.feed = NSOrderedSet(array: cacheFeed)
		localCache.timestamp = timestamp
	}

	private func entity(for localFeedImage: LocalFeedImage, withManagedContext managedContext: NSManagedObjectContext) -> CacheFeedImage {
		let feedImage = CacheFeedImage(context: managedContext)

		feedImage.id = localFeedImage.id
		feedImage.imageDescription = localFeedImage.description
		feedImage.location = localFeedImage.location
		feedImage.url = localFeedImage.url

		return feedImage
	}
}
