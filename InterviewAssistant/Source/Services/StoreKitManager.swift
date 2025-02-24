//
//  StoreKitManager.swift
//  InterviewAssistant
//
//  Created by j0c1epm on 2/21/25.
//


// Managers/StoreKitManager.swift
import StoreKit
import FirebaseFirestore
import FirebaseAuth

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    static let productID = "nextjobai.premium"
    
    @Published private(set) var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published private(set) var isLoading = false
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    func loadProducts() async {
        print("🔄 Loading products...")
        isLoading = true
        
        do {
            products = try await Product.products(for: [Self.productID])
            print("✅ Products loaded: \(products.count)")
            print("Products: \(products.map { $0.id })")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        print("Starting purchase for product: \(product.id)")
        do {
            let result = try await product.purchase()
            print("Purchase result received: \(result)")
            
            switch result {
            case .success(let verification):
                print("Purchase succeeded, verifying transaction")
                let transaction = try checkVerified(verification)
                print("Transaction verified: \(transaction.id)")
                
                await updateSubscriptionInFirebase(
                    isSubscribed: true,
                    productId: product.id,
                    transaction: transaction
                )
                await transaction.finish()
                await updateCustomerProductStatus()
                return transaction
                
            case .pending:
                print("Purchase is pending")
                throw StoreError.pending
            case .userCancelled:
                print("Purchase was cancelled by user")
                throw StoreError.userCancelled
            @unknown default:
                print("Unknown purchase result")
                throw StoreError.unknown
            }
        } catch {
            print("Purchase failed: \(error)")
            throw error
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    print("New transaction received: \(transaction.id)")
                    await self.handleVerifiedTransaction(transaction)
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    private func handleVerifiedTransaction(_ transaction: StoreKit.Transaction) async {
        if transaction.revocationDate == nil {
            await updateSubscriptionInFirebase(
                isSubscribed: true,
                productId: transaction.productID,
                transaction: transaction
            )
        } else {
            await updateSubscriptionInFirebase(
                isSubscribed: false,
                productId: transaction.productID,
                transaction: transaction
            )
        }
        
        await updateCustomerProductStatus()
    }
    
    private func updateCustomerProductStatus() async {
        var validProducts = Set<String>()
        
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate == nil {
                    validProducts.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify transaction: \(error.localizedDescription)")
            }
        }
        
        purchasedProductIDs = validProducts
    }
    
    private func updateSubscriptionInFirebase(isSubscribed: Bool, productId: String, transaction: StoreKit.Transaction) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let subscriptionStatus = User.SubscriptionStatus(
            isSubscribed: isSubscribed,
            subscriptionId: String(transaction.id),
            expirationDate: transaction.expirationDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60),
            productId: productId,
            freeInterviewsRemaining: isSubscribed ? 0 : 1
        )
        
        do {
            try await FirebaseManager.shared.updateSubscriptionStatus(
                userId: userId,
                status: subscriptionStatus
            )
        } catch {
            print("Failed to update subscription in Firebase: \(error.localizedDescription)")
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

extension StoreKitManager {
    enum StoreError: LocalizedError {
        case failedVerification
        case pending
        case userCancelled
        case unknown
        case networkError
        
        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "Transaction verification failed"
            case .pending:
                return "Transaction is pending approval"
            case .userCancelled:
                return "Transaction was cancelled"
            case .unknown:
                return "An unknown error occurred"
            case .networkError:
                return "Network connection error"
            }
        }
    }
}

extension StoreKitManager {
    var hasSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    func product(for id: String) -> Product? {
        products.first(where: { $0.id == id })
    }
}

enum StoreError: Error {
    case failedVerification
}
