//
//  ProPaywallSheet.swift
//  Trailnote
//
//  Created by Jaye Mondale on 9/8/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import StoreKit

struct ProPaywallSheet: View {
    let triggerFeature: String

    @Environment(EntitlementManager.self) private var entitlements
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    featureList
                    purchaseSection
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Maybe Later") { dismiss() }
                }
            }
            .onChange(of: entitlements.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
                .padding(.top, 8)

            Text("Journey Images Pro")
                .font(.title.bold())

            Text("Unlock \(triggerFeature) and all other Pro features.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProFeatureRow(icon: "square.and.arrow.up", title: "PDF Export",
                          description: "Share trips as beautiful journals")
            ProFeatureRow(icon: "wand.and.stars", title: "Smart Trip Suggestions",
                          description: "Auto-file photos into the right trip")
            ProFeatureRow(icon: "icloud", title: "iCloud Sync",
                          description: "Access your trips on every device")
            ProFeatureRow(icon: "rectangle.stack", title: "Home Screen Widget",
                          description: "See your latest trip at a glance")
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await entitlements.purchase() }
            } label: {
                if entitlements.isPurchasing {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                } else {
                    Text(entitlements.proProduct.map { "Unlock for \($0.displayPrice)" } ?? "Loading…")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(entitlements.proProduct == nil || entitlements.isPurchasing)

            Button("Restore Purchases") {
                Task { await entitlements.restorePurchases() }
            }
            .font(.footnote)
            .disabled(entitlements.isPurchasing)

            if let error = entitlements.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview {
    ProPaywallSheet(triggerFeature: "PDF Export")
        .environment(EntitlementManager())
}
