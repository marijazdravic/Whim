//
//  EntryListPrototypeView.swift
//  Whim Prototype
//
//  Created by Marija Zdravic on 01.05.2026..
//

import SwiftUI

struct EntryListPrototypeView: View {
    enum State {
        case loading
        case empty
        case error
        case loaded([EntryListPrototypeItem])
    }

    let state: State

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphericBackground()

                switch state {
                case .loading:
                    LoadingStateView()

                case .empty:
                    EmptyStateView()

                case .error:
                    ErrorStateView()

                case let .loaded(entries):
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(entries) { entry in
                                EntryListPrototypeRow(entry: entry)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Whims")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Image(systemName: "camera.fill")
                    }
                    .accessibilityLabel("Capture")
                }
            }
        }
    }
}

private struct EntryListPrototypeRow: View {
    let entry: EntryListPrototypeItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if entry.hasImage {
                RoundedRectangle(cornerRadius: 8)
                    .fill(entry.imageGradient)
                    .frame(width: 74, height: 74)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.82))
                    }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.timestamp)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 12)

                    ModalityBadges(entry: entry)
                }

                if let text = entry.text {
                    Text(text)
                        .font(.body)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                } else {
                    Text(entry.fallbackTitle)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                }

                if entry.hasAudio {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform")
                        Text("Audio note")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.09, green: 0.35, blue: 0.31))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.78, green: 0.93, blue: 0.88))
                    )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.76))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.45), lineWidth: 1)
        )
    }
}

private struct ModalityBadges: View {
    let entry: EntryListPrototypeItem

    var body: some View {
        HStack(spacing: 6) {
            if entry.text != nil {
                Image(systemName: "text.alignleft")
            }
            if entry.hasImage {
                Image(systemName: "photo.fill")
            }
            if entry.hasAudio {
                Image(systemName: "mic.fill")
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
    }
}

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
            Text("Loading whims")
                .font(.headline)
        }
        .foregroundStyle(.secondary)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
            Text("No whims yet.")
                .font(.title3.weight(.semibold))
            Text("Capture your first thought")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(32)
    }
}

private struct ErrorStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(Color(red: 0.76, green: 0.21, blue: 0.18))
            Text("Couldn't load entries.")
                .font(.headline)
            Button("Try Again") {}
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }
}

private struct AtmosphericBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.96, blue: 0.93),
                Color(red: 0.82, green: 0.91, blue: 0.91),
                Color(red: 0.91, green: 0.84, blue: 0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct EntryListPrototypeItem: Identifiable {
    let id: UUID
    let text: String?
    let timestamp: String
    let hasImage: Bool
    let hasAudio: Bool
    let imageGradient: LinearGradient

    var fallbackTitle: String {
        if hasImage && hasAudio { return "Image and audio note" }
        if hasImage { return "Image note" }
        if hasAudio { return "Audio note" }
        return "Untitled whim"
    }
}

extension EntryListPrototypeItem {
    static let samples = [
        EntryListPrototypeItem(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!,
            text: "Voice memo about the floating capture button: keep it thumb reachable but not loud.",
            timestamp: "5 minutes ago",
            hasImage: false,
            hasAudio: true,
            imageGradient: .warm
        ),
        EntryListPrototypeItem(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!,
            text: "Mood board for the evening version of the capture screen.",
            timestamp: "1 hour ago",
            hasImage: true,
            hasAudio: false,
            imageGradient: .dusk
        ),
        EntryListPrototypeItem(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000003")!,
            text: nil,
            timestamp: "Yesterday",
            hasImage: true,
            hasAudio: true,
            imageGradient: .mint
        )
    ]
}

private extension LinearGradient {
    static let warm = LinearGradient(
        colors: [
            Color(red: 0.96, green: 0.55, blue: 0.42),
            Color(red: 0.98, green: 0.79, blue: 0.43)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let dusk = LinearGradient(
        colors: [
            Color(red: 0.31, green: 0.38, blue: 0.58),
            Color(red: 0.79, green: 0.53, blue: 0.62)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let mint = LinearGradient(
        colors: [
            Color(red: 0.29, green: 0.66, blue: 0.55),
            Color(red: 0.76, green: 0.88, blue: 0.65)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

#Preview("Loaded") {
    EntryListPrototypeView(state: .loaded(EntryListPrototypeItem.samples))
}

#Preview("Empty") {
    EntryListPrototypeView(state: .empty)
}

#Preview("Loading") {
    EntryListPrototypeView(state: .loading)
}

#Preview("Error") {
    EntryListPrototypeView(state: .error)
}
