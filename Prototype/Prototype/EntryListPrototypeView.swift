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
                FuturisticAtmosphericBackground()

                switch state {
                case .loading:
                    LoadingStateView()

                case .empty:
                    EmptyStateView()

                case .error:
                    ErrorStateView()

                case let .loaded(entries):
                    TimelineCloudList(entries: entries)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Whim")
                        .font(.system(size: 28, weight: .regular, design: .serif).italic())
                        .foregroundStyle(.white.opacity(0.92))
                        .shadow(color: .cyan.opacity(0.34), radius: 12, x: 0, y: 4)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Image(systemName: "sparkle")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(
                                Circle()
                                    .stroke(.white.opacity(0.44), lineWidth: 1)
                            )
                            .shadow(color: .cyan.opacity(0.22), radius: 14, x: 0, y: 8)
                    }
                    .accessibilityLabel("Capture")
                }
            }
        }
    }
}

private struct TimelineCloudList: View {
    let entries: [EntryListPrototypeItem]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack(alignment: .top, spacing: 10) {
                            TimelineMarker(
                                index: index,
                                isFirst: index == 0,
                                isLast: index == entries.count - 1,
                                accent: entry.accent
                            )

                            EntryListPrototypeRow(entry: entry, index: index)
                        }
                    }
                }
                .padding(.leading, 30)
                .padding(.trailing, 18)
                .padding(.top, 82)
                .padding(.bottom, 116)
            }
            .scrollIndicators(.hidden)

            FloatingPrototypeControls()
                .padding(.bottom, 22)
        }
    }
}

private struct TimelineMarker: View {
    let index: Int
    let isFirst: Bool
    let isLast: Bool
    let accent: Color

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(lineGradient)
                .frame(width: 1, height: isFirst ? 24 : 38)
                .opacity(isFirst ? 0.28 : 0.72)

            ZStack {
                Circle()
                    .fill(accent.opacity(0.18))
                    .frame(width: 22, height: 22)
                    .blur(radius: 5)

                Circle()
                    .fill(.white)
                    .frame(width: 6, height: 6)
                    .shadow(color: accent, radius: 12, x: 0, y: 0)

                Circle()
                    .stroke(.white.opacity(0.36), lineWidth: 0.7)
                    .frame(width: 16, height: 16)
            }
            .overlay(alignment: .topLeading) {
                if index == 0 {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.78, blue: 0.92))
                        .frame(width: 5, height: 5)
                        .shadow(color: Color(red: 1.0, green: 0.56, blue: 0.86), radius: 8)
                        .offset(x: -3, y: -15)
                }
            }

            Rectangle()
                .fill(lineGradient)
                .frame(width: 1, height: isLast ? 40 : 98)
                .opacity(isLast ? 0.26 : 0.72)
        }
        .frame(width: 20)
        .padding(.top, 2)
    }

    private var lineGradient: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.3),
                accent.opacity(0.9),
                .white.opacity(0.72)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct FloatingPrototypeControls: View {
    var body: some View {
        HStack(spacing: 44) {
            FloatingControlButton(systemName: "sparkle")

            Button {} label: {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white)
                    .frame(width: 66, height: 66)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.78),
                                        Color(red: 0.54, green: 0.98, blue: 0.9).opacity(0.72),
                                        Color(red: 0.9, green: 0.66, blue: 1.0).opacity(0.58)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color(red: 0.54, green: 0.98, blue: 0.9).opacity(0.34), radius: 24, x: 0, y: 10)
            }
            .accessibilityLabel("New whim")

            FloatingControlButton(systemName: "slider.horizontal.3")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.black.opacity(0.02))
                .background(.ultraThinMaterial, in: Capsule())
        )
    }
}

private struct FloatingControlButton: View {
    let systemName: String

    var body: some View {
        Button {} label: {
            Image(systemName: systemName)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 42, height: 42)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.24), lineWidth: 1)
                )
        }
    }
}

private struct EntryListPrototypeRow: View {
    let entry: EntryListPrototypeItem
    let index: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MemoryCardBackground(accent: entry.accent)

            HStack(alignment: .top, spacing: 14) {
                if entry.hasImage {
                    MemoryShardThumbnail(gradient: entry.imageGradient, accent: entry.accent)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(entry.title)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.92))

                        Spacer(minLength: 10)

                        Text(entry.timestamp)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.66))
                    }

                    if let text = entry.text {
                        Text(text)
                            .font(.system(.callout, design: .rounded))
                            .lineLimit(2)
                            .foregroundStyle(.white.opacity(0.78))
                    } else {
                        Text(entry.fallbackTitle)
                            .font(.system(.callout, design: .rounded, weight: .medium))
                            .foregroundStyle(.white.opacity(0.78))
                    }

                    HStack(spacing: 8) {
                        ContentChips(entry: entry)
                    }

                    if entry.hasAudio && !entry.hasImage {
                        AudioWaveformChip(accent: entry.accent)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            MemoryFacetEdge(accent: entry.accent)
                .offset(x: 3, y: 0)
        }
        .frame(maxWidth: 292)
        .offset(x: horizontalOffset)
        .shadow(color: entry.accent.opacity(0.18), radius: 22, x: 0, y: 16)
    }

    private var horizontalOffset: CGFloat {
        [-1, 7, 1, 5][index % 4]
    }
}

private struct ContentChips: View {
    let entry: EntryListPrototypeItem

    var body: some View {
        HStack(spacing: 7) {
            if entry.text != nil {
                SubtleContentChip(systemName: "textformat")
            }
            if entry.hasImage {
                SubtleContentChip(systemName: "photo")
            }
            if entry.hasAudio {
                SubtleContentChip(systemName: "waveform")
            }
        }
    }
}

private struct SubtleContentChip: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.72))
            .frame(width: 28, height: 22)
            .background(.white.opacity(0.08), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.14), lineWidth: 0.7)
            )
    }
}

private struct MemoryCardBackground: View {
    let accent: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                accent.opacity(0.08),
                                .white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.46),
                                accent.opacity(0.26),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.9
                    )
            )
    }
}

private struct MemoryShardThumbnail: View {
    let gradient: LinearGradient
    let accent: Color

    var body: some View {
        ZStack {
            CrystalHalo(accent: accent)
                .frame(width: 76, height: 76)

            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 22,
                topTrailingRadius: 10,
                style: .continuous
            )
            .fill(gradient)
            .frame(width: 62, height: 62)
            .overlay {
                Image(systemName: "photo")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 12,
                    bottomTrailingRadius: 22,
                    topTrailingRadius: 10,
                    style: .continuous
                )
                .stroke(.white.opacity(0.42), lineWidth: 0.9)
            )
            .shadow(color: accent.opacity(0.18), radius: 12, x: 0, y: 8)
        }
        .frame(width: 76, height: 76)
    }
}

private struct CrystalHalo: View {
    let accent: Color

    var body: some View {
        AngularGradient(
            colors: [
                .white.opacity(0.1),
                accent.opacity(0.28),
                Color(red: 0.78, green: 0.68, blue: 1.0).opacity(0.2),
                .white.opacity(0.06),
                accent.opacity(0.28)
            ],
            center: .center
        )
        .clipShape(CrystalShardShape())
        .blur(radius: 0.2)
        .overlay(
            CrystalShardShape()
                .stroke(.white.opacity(0.22), lineWidth: 0.6)
        )
    }
}

private struct CrystalShardShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.88, y: rect.minY + rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.74, y: rect.maxY * 0.86))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.18, y: rect.maxY * 0.74))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.22, y: rect.minY + rect.height * 0.16))
        path.closeSubpath()
        return path
    }
}

private struct AudioWaveformChip: View {
    let accent: Color

    private let bars: [CGFloat] = [0.22, 0.54, 0.38, 0.78, 0.46, 0.92, 0.34, 0.62, 0.28]

    var body: some View {
        HStack(spacing: 10) {
            HStack(alignment: .center, spacing: 3) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, height in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.94), accent.opacity(0.82)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4, height: 24 * height)
                }
            }
            .frame(width: 66, height: 28)

            Text("Voice")
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.74))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(.white.opacity(0.08), in: Capsule())
        .overlay(
            Capsule()
                .stroke(accent.opacity(0.26), lineWidth: 0.8)
        )
    }
}

private struct MemoryFacetEdge: View {
    let accent: Color

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            Path { path in
                path.move(to: CGPoint(x: 0, y: 18))
                path.addLine(to: CGPoint(x: 18, y: 0))
                path.addLine(to: CGPoint(x: 24, y: 52))
                path.addLine(to: CGPoint(x: 4, y: 74))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [accent.opacity(0.18), .white.opacity(0.08), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 28, height: 78)
            .blur(radius: 0.3)
        }
        .allowsHitTesting(false)
    }
}

private struct LoadingStateView: View {
    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                CrystalHalo(accent: .cyan)
                    .frame(width: 88, height: 88)
                ProgressView()
                    .tint(.white)
            }
            Text("Loading whims")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 14) {
            CrystalHalo(accent: Color(red: 0.56, green: 0.92, blue: 0.9))
                .frame(width: 110, height: 110)
                .overlay {
                    Image(systemName: "sparkles")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            Text("No whims yet.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("Capture your first thought")
                .font(.body)
                .foregroundStyle(.white.opacity(0.66))
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
                .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.62))
            Text("Couldn't load entries.")
                .font(.headline)
                .foregroundStyle(.white)
            Button("Try Again") {}
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }
}

private struct FuturisticAtmosphericBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.10, blue: 0.13),
                    Color(red: 0.12, green: 0.27, blue: 0.30),
                    Color(red: 0.42, green: 0.34, blue: 0.58),
                    Color(red: 0.96, green: 0.88, blue: 0.74)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.42, green: 0.98, blue: 0.89).opacity(0.26))
                .frame(width: 260, height: 260)
                .blur(radius: 58)
                .offset(x: -130, y: -250)

            Circle()
                .fill(Color(red: 0.78, green: 0.58, blue: 1.0).opacity(0.24))
                .frame(width: 310, height: 310)
                .blur(radius: 72)
                .offset(x: 150, y: -70)

            Circle()
                .fill(Color(red: 1.0, green: 0.82, blue: 0.48).opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 64)
                .offset(x: 80, y: 320)

            LinearGradient(
                colors: [.black.opacity(0.24), .clear, .black.opacity(0.32)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

struct EntryListPrototypeItem: Identifiable {
    let id: UUID
    let title: String
    let text: String?
    let timestamp: String
    let hasImage: Bool
    let hasAudio: Bool
    let imageGradient: LinearGradient
    let accent: Color

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
            title: "Midday thought",
            text: "Voice memo about the floating capture button: keep it thumb reachable but not loud.",
            timestamp: "5 minutes ago",
            hasImage: false,
            hasAudio: true,
            imageGradient: .warm,
            accent: Color(red: 0.54, green: 0.98, blue: 0.9)
        ),
        EntryListPrototypeItem(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!,
            title: "Upstate Drive Idea",
            text: "Mood board for the evening version of the capture screen.",
            timestamp: "1 hour ago",
            hasImage: true,
            hasAudio: false,
            imageGradient: .dusk,
            accent: Color(red: 0.78, green: 0.64, blue: 1.0)
        ),
        EntryListPrototypeItem(
            id: UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000003")!,
            title: "Voice note idea",
            text: nil,
            timestamp: "Yesterday",
            hasImage: true,
            hasAudio: true,
            imageGradient: .mint,
            accent: Color(red: 0.96, green: 0.74, blue: 0.48)
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

struct EntryListPrototypeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EntryListPrototypeView(state: .loaded(EntryListPrototypeItem.samples))
                .previewDisplayName("Loaded")

            EntryListPrototypeView(state: .empty)
                .previewDisplayName("Empty")

            EntryListPrototypeView(state: .loading)
                .previewDisplayName("Loading")

            EntryListPrototypeView(state: .error)
                .previewDisplayName("Error")
        }
    }
}
