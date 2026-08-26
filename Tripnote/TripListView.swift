//
//  TripListView.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import SwiftData

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]

    @State private var isPresentingNewTrip = false
    @State private var searchText = ""

    private var filteredTrips: [Trip] {
        guard !searchText.isEmpty else { return trips }
        let lower = searchText.lowercased()
        return trips.filter { trip in
            trip.name.lowercased().contains(lower) ||
            (trip.notes ?? []).contains { note in
                note.text.lowercased().contains(lower)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    ContentUnavailableView {
                        Label("No Trips Yet", systemImage: "map")
                    } description: {
                        Text("Start a trip to begin capturing memories.")
                    } actions: {
                        Button("Create Trip") {
                            isPresentingNewTrip = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if filteredTrips.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredTrips) { trip in
                            NavigationLink(value: trip) {
                                TripRow(trip: trip)
                            }
                        }
                        .onDelete(perform: deleteTrips)
                    }
                }
            }
            .navigationTitle("Tripnote")
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
            .searchable(text: $searchText, prompt: "Search trips and notes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingNewTrip = true
                    } label: {
                        Label("New Trip", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewTrip) {
                NewTripSheet()
            }
            .onAppear {
                WidgetDataManager.update(with: trips.first)
            }
            .onChange(of: trips) { _, newTrips in
                WidgetDataManager.update(with: newTrips.first)
            }
        }
    }

    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredTrips[index])
        }
    }
}

private struct TripRow: View {
    let trip: Trip

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.name)
                    .font(.headline)
                Text(dateRangeText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = trip.coverPhoto?.thumbnailData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(.quaternary)
                .frame(width: 56, height: 56)
                .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
        }
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if let endDate = trip.endDate, !Calendar.current.isDate(endDate, inSameDayAs: trip.startDate) {
            return "\(formatter.string(from: trip.startDate)) – \(formatter.string(from: endDate))"
        }
        return formatter.string(from: trip.startDate)
    }
}

private struct NewTripSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var startDate = Date.now
    @State private var hasEndDate = false
    @State private var endDate = Date.now

    var body: some View {
        NavigationStack {
            Form {
                TextField("Trip Name", text: $name)
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                Toggle("Multi-day trip", isOn: $hasEndDate.animation())
                if hasEndDate {
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
            }
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trip = Trip(name: name, startDate: startDate, endDate: hasEndDate ? endDate : nil)
                        modelContext.insert(trip)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    TripListView()
        .modelContainer(for: [Trip.self, TripEvent.self, Note.self, Photo.self], inMemory: true)
}
