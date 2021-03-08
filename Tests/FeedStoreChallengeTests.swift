//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge

class FeedStoreChallengeTests: XCTestCase, FeedStoreSpecs {
	
	//  ***********************
	//
	//  Follow the TDD process:
	//
	//  1. Uncomment and run one test at a time (run tests with CMD+U).
	//  2. Do the minimum to make the test pass and commit.
	//  3. Refactor if needed and commit again.
	//
	//  Repeat this process until all tests are passing.
	//
	//  ***********************

	func test_retrieve_deliversEmptyOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_retrieve_deliversFoundValuesOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
	}
	
	func test_retrieve_hasNoSideEffectsOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_insert_overridesPreviouslyInsertedCacheValues() throws {
		let sut = try makeSUT()

		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}
	
	func test_delete_deliversNoErrorOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_delete_hasNoSideEffectsOnEmptyCache() throws {
		let sut = try makeSUT()

		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_delete_deliversNoErrorOnNonEmptyCache() throws {
		let sut = try makeSUT()

		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_delete_emptiesPreviouslyInsertedCache() throws {
		let sut = try makeSUT()

		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}
	
	func test_storeSideEffects_runSerially() throws {
		let sut = try makeSUT()

		assertThatSideEffectsRunSerially(on: sut)
	}
	
	// - MARK: Helpers
	
	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> FeedStore {
		let sut = try CoreDataFeedStore(storeURL: URL(fileURLWithPath: "/dev/null"), bundle: Bundle(for: FeedStoreChallengeTests.self))
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}

	private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
		addTeardownBlock { [weak instance] in
			XCTAssertNil(instance, file: file, line: line)
		}
	}
}

import CoreData

class CoreDataFeedStore: FeedStore {

	enum CoreDataError: Error {
		case unableToFindModel
		case unableToLoad(Error)
	}

	private let storeURL: URL
	private let bundle: Bundle

	private static let resourceName: String = "FeedStore"

	private let persistentContainer: NSPersistentContainer
	private let context: NSManagedObjectContext

	init(storeURL: URL, bundle: Bundle = .main) throws {
		self.storeURL = storeURL
		self.bundle = bundle
		self.persistentContainer = try CoreDataFeedStore.loadPersistendContainer(storeURL: storeURL, bundle: bundle)
		self.context = persistentContainer.newBackgroundContext()
	}

	private static func loadPersistendContainer(storeURL: URL, bundle: Bundle) throws -> NSPersistentContainer {
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

	func retrieve(completion: @escaping RetrievalCompletion) {
		let managedContext = context
		do {
			let fetchRequest = NSFetchRequest<LocalCache>(entityName: "LocalCache")

			let result = try managedContext.fetch(fetchRequest)
			if let cacheResult = result.first {
				completion(.found(feed: cacheResult.feed.array.compactMap { ($0 as? CacheFeedImage)?.localFeedImage } , timestamp: cacheResult.timestamp))
			} else {
				completion(.empty)
			}
		} catch {
			completion(.failure(error))
		}
	}
}

extension CoreDataFeedStore {

	func deleteCachedFeed(completion: @escaping DeletionCompletion) {
		let managedContext = context
		do {
			self.deleteCurrentCacheIfNeeded(in: managedContext)
			try managedContext.save()

			completion(nil)
		} catch {
			completion(error)
		}
	}
}

extension CoreDataFeedStore {

	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		let managedContext = context
		do {
			self.deleteCurrentCacheIfNeeded(in: managedContext)
			self.createNewCachedFeed(feed, timestamp: timestamp, in: managedContext)

			try managedContext.save()

			completion(nil)
		} catch {
			completion(error)
		}
	}

	private func createNewCachedFeed(_ feed: [LocalFeedImage], timestamp: Date, in context: NSManagedObjectContext) {
		var cacheFeed = [CacheFeedImage]()
		feed.forEach { cacheFeed.append(self.entity(for: $0, withManagedContext: context))}


		let cacheEntity = NSEntityDescription.entity(forEntityName: LocalCache.className(), in: context)!
		let localCache = LocalCache(entity: cacheEntity, insertInto: context)
		localCache.feed = NSOrderedSet(array: cacheFeed)
		localCache.timestamp = timestamp
	}

	private func entity(for localFeedImage: LocalFeedImage, withManagedContext managedContext: NSManagedObjectContext) -> CacheFeedImage {
		let entity = NSEntityDescription.entity(forEntityName: CacheFeedImage.className(), in: managedContext)!
		let feedImage = CacheFeedImage(entity: entity, insertInto: managedContext)

		feedImage.id = localFeedImage.id
		feedImage.imageDescription = localFeedImage.description ?? ""
		feedImage.location = localFeedImage.location ?? ""
		feedImage.url = localFeedImage.url

		return feedImage
	}
}
