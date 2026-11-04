import XCTest
@testable import BestBasket

@MainActor
final class BestBasketFeatureTests: XCTestCase {
    func testBasketPlanIncludesOneDeliveryFeePerUsedPlatform() {
        let product = makeProduct("milk")
        let blinkit = makeOffer(id: "milk-a", productID: product.id, retailer: "A", price: 30, fee: 5, platformFee: 2)
        let zepto = makeOffer(id: "milk-b", productID: product.id, retailer: "B", price: 28, fee: 12, platformFee: 3)
        let line = BasketLine(id: "line", offerID: blinkit.id, quantity: 2)

        let result = BasketCalculator.calculate(lines: [line], products: [product], offers: [blinkit, zepto],
                                                platforms: ["A", "B"], preferences: .defaults)

        XCTAssertEqual(result.subtotal, 60)
        XCTAssertEqual(result.deliveryFees, 5)
        XCTAssertEqual(result.platformFees, 2)
        XCTAssertEqual(result.total, 67)
        XCTAssertEqual(result.cheapestSinglePlatform?.total, 67)
        XCTAssertEqual(result.cheapestSinglePlatform?.platforms, ["A"])
    }

    func testMixedPlatformPlanWinsOnlyAfterFeesAndMeaningfulSavings() {
        let first = makeProduct("first")
        let second = makeProduct("second")
        let offers = [
            makeOffer(id: "first-a", productID: first.id, retailer: "A", price: 100, fee: 5),
            makeOffer(id: "first-b", productID: first.id, retailer: "B", price: 180, fee: 7),
            makeOffer(id: "second-a", productID: second.id, retailer: "A", price: 180, fee: 5),
            makeOffer(id: "second-b", productID: second.id, retailer: "B", price: 100, fee: 7)
        ]
        let lines = [BasketLine(id: "one", offerID: "first-a", quantity: 1),
                     BasketLine(id: "two", offerID: "second-a", quantity: 1)]

        let result = BasketCalculator.calculate(lines: lines, products: [first, second], offers: offers,
                                                platforms: ["A", "B"], preferences: .defaults)

        XCTAssertEqual(result.cheapestSinglePlatform?.total, 285)
        XCTAssertEqual(result.bestMultiPlatform?.total, 212)
        XCTAssertEqual(result.recommendedPlan?.platforms, ["A", "B"])
        XCTAssertEqual(result.recommendedPlan?.total, 212)
    }

    func testSinglePlatformComparisonMarksExcludedProductsAsPartial() {
        let first = makeProduct("first")
        let second = makeProduct("second")
        let offers = [
            makeOffer(id: "first-a", productID: first.id, retailer: "A", price: 20, fee: 5),
            makeOffer(id: "first-b", productID: first.id, retailer: "B", price: 22, fee: 7),
            makeOffer(id: "second-b", productID: second.id, retailer: "B", price: 30, fee: 7)
        ]
        let lines = [BasketLine(id: "one", offerID: "first-a", quantity: 1),
                     BasketLine(id: "two", offerID: "second-b", quantity: 1)]

        let result = BasketCalculator.calculate(lines: lines, products: [first, second], offers: offers,
                                                platforms: ["A", "B"], preferences: .defaults)

        let partialA = result.singlePlatformPlans.first(where: { $0.name == "A only" })
        XCTAssertFalse(partialA?.isComplete ?? true)
        XCTAssertEqual(partialA?.excludedProducts, [second.name])
        XCTAssertEqual(result.cheapestSinglePlatform?.name, "B only")
    }

    func testBasketWatchOnlyFindsMeaningfulOffersForBasketProducts() {
        let product = makeProduct("basket-product")
        let unrelated = makeProduct("unrelated")
        let current = makeOffer(id: "current", productID: product.id, retailer: "A", price: 100, fee: 10)
        let better = makeOffer(id: "better", productID: product.id, retailer: "B", price: 90, fee: 10, discount: 5)
        let unrelatedOffer = makeOffer(id: "unrelated-offer", productID: unrelated.id, retailer: "B", price: 1, fee: 0)
        let line = BasketLine(id: "line", offerID: current.id, quantity: 2)

        let deals = BasketWatchService.deals(lines: [line], products: [product, unrelated],
                                             offers: [current, better, unrelatedOffer])

        XCTAssertEqual(deals.count, 1)
        XCTAssertEqual(deals.first?.product.id, product.id)
        XCTAssertEqual(deals.first?.suggestedOffer.id, better.id)
        XCTAssertEqual(deals.first?.savings, 30)
    }

    func testRecipeIngredientAliasesMatchAvailableIngredients() {
        let recipe = RecipeCatalogService.recipes.first(where: { $0.id == "paneer-bhurji" })!
        let match = RecipeCatalogService.match(recipe, available: ["paneer", "tomato"])

        XCTAssertEqual(match.availableIngredients.map(\.name), ["Paneer", "Tomatoes"])
        XCTAssertTrue(match.missingIngredients.contains(where: { $0.name == "Onions" }))
        XCTAssertEqual(match.matchPercent, 50)
    }

    func testBasketAndSavedListsSurviveRepositoryRecreation() throws {
        let suiteName = "BestBasketTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let firstRepository = UserDefaultsAppStateRepository(store: defaults)
        let line = BasketLine(id: "milk-line", offerID: "amul-milk-Blinkit", quantity: 3)
        firstRepository.save([line])
        var state = firstRepository.appState
        state.savedLists = [SavedGroceryList(name: "Weekly", items: [GroceryListItem(productID: "amul-milk", quantity: 2)])]
        state.basketWatchEnabled = false
        let reminderDate = Date(timeIntervalSince1970: 1_800_000_000)
        state.reminders = [RefillReminder(id: "milk-reminder", productID: "amul-milk", interval: .custom(days: 12),
                                           lastPurchaseAt: reminderDate.addingTimeInterval(-86400),
                                           nextReminderAt: reminderDate, enabled: true)]
        state.dealNotifications = [BasketDealNotification(id: "sample-deal", productID: "amul-milk",
                                                            originalOfferID: "old", suggestedOfferID: "new",
                                                            estimatedSavings: 12, kind: .betterOffer,
                                                            createdAt: reminderDate, readAt: reminderDate)]
        firstRepository.appState = state

        let restored = UserDefaultsAppStateRepository(store: defaults)
        XCTAssertEqual(restored.lines(), [line])
        XCTAssertEqual(restored.appState.savedLists.first?.name, "Weekly")
        XCTAssertFalse(restored.appState.basketWatchEnabled)
        XCTAssertEqual(restored.appState.reminders.first?.interval, .custom(days: 12))
        XCTAssertNotNil(restored.appState.dealNotifications.first?.readAt)
    }

    func testApplyingBasketDealKeepsQuantityAndDoesNotDuplicateProduct() throws {
        let suiteName = "BestBasketWatchTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let product = makeProduct("watch-item")
        let current = makeOffer(id: "watch-a", productID: product.id, retailer: "A", price: 100, fee: 5)
        let better = makeOffer(id: "watch-b", productID: product.id, retailer: "B", price: 90, fee: 5)
        let products = StubProductRepository(products: [product], offers: [current, better])
        let basket = InMemoryBasketRepository()
        basket.save([BasketLine(id: "line", offerID: current.id, quantity: 4)])
        let appState = UserDefaultsAppStateRepository(store: defaults)
        let watch = TrackingViewModel(productRepository: products, appStateRepository: appState, basketRepository: basket)
        let deal = try XCTUnwrap(watch.deals.first)

        watch.apply(deal)

        XCTAssertEqual(basket.lines().count, 1)
        XCTAssertEqual(basket.lines().first?.quantity, 4)
        XCTAssertEqual(basket.lines().first?.offerID, better.id)
        XCTAssertNotNil(watch.notifications.first?.readAt)
        let notificationCount = watch.notifications.count
        watch.refreshNotifications()
        XCTAssertEqual(watch.notifications.count, notificationCount)
    }

    func testApplyingCompleteBasketPlanPreservesTheExistingLineQuantity() throws {
        let product = makeProduct("plan-item")
        let current = makeOffer(id: "plan-a", productID: product.id, retailer: "A", price: 100, fee: 5)
        let cheaper = makeOffer(id: "plan-b", productID: product.id, retailer: "B", price: 80, fee: 5)
        let repository = StubProductRepository(products: [product], offers: [current, cheaper])
        let basketRepository = InMemoryBasketRepository()
        basketRepository.save([BasketLine(id: "existing", offerID: current.id, quantity: 6)])
        let model = BasketViewModel(productRepository: repository, basketRepository: basketRepository,
                                    preferencesRepository: InMemoryPreferencesRepository())
        let plan = try XCTUnwrap(model.summary.recommendedPlan)

        model.apply(plan)

        XCTAssertEqual(basketRepository.lines().count, 1)
        XCTAssertEqual(basketRepository.lines().first?.id, "existing")
        XCTAssertEqual(basketRepository.lines().first?.quantity, 6)
        XCTAssertEqual(basketRepository.lines().first?.offerID, cheaper.id)
    }

    func testGroceryListsStaySeparateAndAddingListMergesIntoBasket() throws {
        let suiteName = "BestBasketLists-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let product = makeProduct("list-item")
        let offer = makeOffer(id: "list-item-a", productID: product.id, retailer: "A", price: 10, fee: 0)
        let repository = StubProductRepository(products: [product], offers: [offer])
        let state = UserDefaultsAppStateRepository(store: defaults)
        let basket = InMemoryBasketRepository()
        basket.save([BasketLine(id: "existing", offerID: offer.id, quantity: 2)])
        let model = GroceryListsViewModel(state: state, products: repository, basket: basket)
        let id = model.create("Weekend")
        let list = try XCTUnwrap(model.lists.first(where: { $0.id == id }))
        model.add(product.id, quantity: 3, to: list)
        XCTAssertEqual(basket.lines().first?.quantity, 2)
        let updatedList = try XCTUnwrap(model.lists.first(where: { $0.id == id }))
        model.addToBasket(updatedList)
        XCTAssertEqual(basket.lines().count, 1)
        XCTAssertEqual(basket.lines().first?.quantity, 5)
        XCTAssertEqual(model.lists.first?.items.first?.quantity, 3)
    }

    private func makeProduct(_ id: String) -> CatalogProduct {
        CatalogProduct(id: id, name: id.capitalized, brand: "Sample", packSize: "1 pack", category: "Pantry",
                       systemImage: "basket", rating: 4, reviewCount: 1, description: "Test product")
    }

    private func makeOffer(id: String, productID: String, retailer: String, price: Int, fee: Int,
                           discount: Int = 0, platformFee: Decimal = 0) -> PriceOffer {
        PriceOffer(id: id, productID: productID, retailer: retailer, price: Decimal(price), originalPrice: nil,
                   discount: Decimal(discount), deliveryFee: Decimal(fee), platformFee: platformFee, available: true,
                   delivery: "20 min", colorName: retailer)
    }

    private final class StubProductRepository: ProductRepository {
        let productValues: [CatalogProduct]
        let offerValues: [PriceOffer]
        init(products: [CatalogProduct], offers: [PriceOffer]) {
            self.productValues = products
            self.offerValues = offers
        }
        func products() -> [CatalogProduct] { productValues }
        func offers(for productID: String) -> [PriceOffer] { offerValues.filter { $0.productID == productID } }
        func allOffers() -> [PriceOffer] { offerValues }
        func platforms() -> [String] { Array(Set(offerValues.map(\.retailer))).sorted() }
    }
}
