//
//  CaptureViewTests.swift
//  WhimiOSTests
//
//  Created by Marija Zdravic on 10.05.2026..
//

import Testing
import ViewInspector
import Whim
@testable import WhimiOS

@MainActor
struct CaptureViewTests {
    @Test
    func captureView_doesNotRequestSaveOnAppearance() throws {
        let creator = AsyncLoaderSpy<CreateEntryInput, Void>()
        let createEntry: CreateEntry = creator.load
        let viewModel = CaptureViewModel(createEntry: createEntry)
        let sut = CaptureView(viewModel: viewModel)

        ViewHosting.host(view: sut)
        defer { ViewHosting.expel() }

        #expect(creator.params.isEmpty)
    }

    @Test
    func captureView_updatesViewModelTextOnUserInput() throws {
        let viewModel = CaptureViewModel(createEntry: { _ in })
        let sut = CaptureView(viewModel: viewModel)

        ViewHosting.host(view: sut)
        defer { ViewHosting.expel() }

        try sut.inspect()
            .find(ViewType.TextField.self)
            .setInput("First whim")

        #expect(viewModel.text == "First whim")
    }
}
