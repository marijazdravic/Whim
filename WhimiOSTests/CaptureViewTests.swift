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
        let (sut, _, creator) = makeSUT()

        ViewHosting.host(view: sut)
        defer { ViewHosting.expel() }

        #expect(creator.params.isEmpty)
    }

    @Test
    func captureView_forwardsUserInputToViewModel() throws {
        let (sut, viewModel, _) = makeSUT()

        ViewHosting.host(view: sut)
        defer { ViewHosting.expel() }

        try sut.inspect()
            .find(ViewType.TextField.self)
            .setInput("First whim")

        #expect(viewModel.text == "First whim")
    }

    // MARK: - Helpers

    private func makeSUT() -> (
        sut: CaptureView,
        viewModel: CaptureViewModel,
        creator: AsyncLoaderSpy<CreateEntryInput, Void>
    ) {
        let creator = AsyncLoaderSpy<CreateEntryInput, Void>()
        let viewModel = CaptureViewModel(createEntry: creator.load)
        let sut = CaptureView(viewModel: viewModel)
        return (sut, viewModel, creator)
    }
}
