//
//  EntitlementManager.swift
//  Trailnote
//
//  Created by Jaye Mondale on 9/8/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import Foundation
import StoreKit

// Must match the product ID you create in App Store Connect.
// For local testing: add a StoreKit Configuration file to the project,
// define this product there, then select it under Product > Scheme > Edit Scheme
// > Run > Options > StoreKit Configuration.
private let proProductID = "journeyimages_pro"

@Observable @MainActor
final class EntitlementManager {
    private(set) var isPro = false
    private(set) var proProduct: Product?
    private(set) var isPurchasing = false
    private(set) var purchaseError: String?

    init() {
        Task { await refresh() }
        Task { await listenForTransactionUpdates() }
    }

    func refresh() async {
        await checkEntitlements()
        await loadProduct()
    }

    private func checkEntitlements() async {
        var foundPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == proProductID {
                foundPro = true
                break
            }
        }
        isPro = foundPro
    }

    private func loadProduct() async {
        guard let product = try? await Product.products(for: [proProductID]).first else { return }
        proProduct = product
    }

    // Handles promotions, family sharing, and other server-side grants.
    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result,
               transaction.productID == proProductID {
                isPro = true
                await transaction.finish()
            }
        }
    }

    func purchase() async {
        guard let product = proProduct, !isPurchasing else { return }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    isPro = true
                    await transaction.finish()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        try? await AppStore.sync()
        await checkEntitlements()
    }
}
