//
//  OnboardingView.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/17/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    let onDismiss: () -> Void

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Tripnote",
            subtitle: "Your personal travel journal for every adventure.",
            systemImage: "map.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "Organize Your Trips",
            subtitle: "Create a trip for any adventure and keep all your memories in one place.",
            systemImage: "airplane",
            color: .orange
        ),
        OnboardingPage(
            title: "Capture Every Moment",
            subtitle: "Add notes and photos as you explore — right from the trip detail screen.",
            systemImage: "camera.fill",
            color: .green
        )
    ]

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(pages.indices, id: \.self) { index in
                pageView(pages[index], isLast: index == pages.count - 1)
                    .tag(index)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
    }

    private func pageView(_ page: OnboardingPage, isLast: Bool) -> some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: page.systemImage)
                .font(.system(size: 80))
                .foregroundStyle(page.color)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            if isLast {
                Button("Get Started") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 60)
            } else {
                Button("Next") {
                    withAnimation { currentPage += 1 }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.bottom, 60)
            }
        }
        .padding()
    }
}

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
}

#Preview {
    OnboardingView(onDismiss: {})
}
