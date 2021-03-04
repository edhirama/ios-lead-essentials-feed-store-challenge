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
//		let sut = try makeSUT()
//
//		assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_insert_deliversNoErrorOnNonEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_insert_overridesPreviouslyInsertedCacheValues() throws {
//		let sut = try makeSUT()
//
//		assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
	}
	
	func test_delete_deliversNoErrorOnEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
	}
	
	func test_delete_hasNoSideEffectsOnEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
	}
	
	func test_delete_deliversNoErrorOnNonEmptyCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
	}
	
	func test_delete_emptiesPreviouslyInsertedCache() throws {
//		let sut = try makeSUT()
//
//		assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
	}
	
	func test_storeSideEffects_runSerially() throws {
//		let sut = try makeSUT()
//
//		assertThatSideEffectsRunSerially(on: sut)
	}
	
	// - MARK: Helpers
	
	private func makeSUT() throws -> FeedStore {
		CoreDataFeedStore(storeType: NSInMemoryStoreType, bundle: Bundle(for: FeedStoreChallengeTests.self))
	}
	
}

import CoreData

class CoreDataFeedStore: FeedStore {

	private let storeType: String
	private let bundle: Bundle

	private static let resourceName: String = "FeedStore"

	lazy var persistentContainer: NSPersistentContainer? = {

		guard let model = NSManagedObjectModel(contentsOf: bundle.url(forResource: CoreDataFeedStore.resourceName, withExtension: "momd")!) else { return nil }

		let container = NSPersistentContainer(name: CoreDataFeedStore.resourceName, managedObjectModel: model)
		let description = NSPersistentStoreDescription(url: URL(fileURLWithPath: "dev/null"))
		description.type = storeType
		container.persistentStoreDescriptions = [description]

		container.loadPersistentStores { description, error in
			if let error = error {
				fatalError("Unable to load persistent stores: \(error)")
			}
		}
		return container
	}()

	init(storeType: String = NSSQLiteStoreType, bundle: Bundle = .main) {
		self.storeType = storeType
		self.bundle = bundle
	}

	func deleteCachedFeed(completion: @escaping DeletionCompletion) {

	}

	func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
		guard let managedContext = persistentContainer?.viewContext else { return completion(NSError(domain: "any", code: -1, userInfo: nil)) }
		var cacheFeed = [CacheFeedImage]()
		feed.forEach { cacheFeed.append(self.entity(for: $0, withManagedContext: managedContext))}


		let cacheEntity = NSEntityDescription.entity(forEntityName: LocalCache.className(), in: managedContext)!
		let localCache = LocalCache(entity: cacheEntity, insertInto: managedContext)
		localCache.feed = NSOrderedSet(array: cacheFeed)
		localCache.timestamp = timestamp
		try! managedContext.save()

		completion(nil)
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

	func retrieve(completion: @escaping RetrievalCompletion) {
		guard let managedContext = persistentContainer?.viewContext else { return completion(.failure(NSError(domain: "any", code: -1, userInfo: nil))) }

		let fetchRequest = NSFetchRequest<LocalCache>(entityName: "LocalCache")

		let result = try! managedContext.fetch(fetchRequest)
		if result.isEmpty {
			completion(.empty)
		} else {
			completion(.found(feed: result.first!.feed.array.compactMap { ($0 as? CacheFeedImage)?.localFeedImage } , timestamp: result.first!.timestamp))
		}
	}

}

//  ***********************
//
//  Uncomment the following tests if your implementation has failable operations.
//
//  Otherwise, delete the commented out code!
//
//  ***********************

//extension FeedStoreChallengeTests: FailableRetrieveFeedStoreSpecs {
//
//	func test_retrieve_deliversFailureOnRetrievalError() throws {
////		let sut = try makeSUT()
////
////		assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
//	}
//
//	func test_retrieve_hasNoSideEffectsOnFailure() throws {
////		let sut = try makeSUT()
////
////		assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
//	}
//
//}

//extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {
//
//	func test_insert_deliversErrorOnInsertionError() throws {
////		let sut = try makeSUT()
////
////		assertThatInsertDeliversErrorOnInsertionError(on: sut)
//	}
//
//	func test_insert_hasNoSideEffectsOnInsertionError() throws {
////		let sut = try makeSUT()
////
////		assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
//	}
//
//}

//extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {
//
//	func test_delete_deliversErrorOnDeletionError() throws {
////		let sut = try makeSUT()
////
////		assertThatDeleteDeliversErrorOnDeletionError(on: sut)
//	}
//
//	func test_delete_hasNoSideEffectsOnDeletionError() throws {
////		let sut = try makeSUT()
////
////		assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
//	}
//
//}
