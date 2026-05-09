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
        let creator = CreateEntrySpy()
        let viewModel = CaptureViewModel(createEntry: creator.create)
        let sut = CaptureView(viewModel: viewModel)

        ViewHosting.host(view: sut)
        defer { ViewHosting.expel() }

        #expect(creator.requestedInputs.isEmpty)
    }
}

@MainActor
private final class CreateEntrySpy {
    private(set) var requestedInputs = [CreateEntryInput]()

    func create(_ input: CreateEntryInput) async throws {
        requestedInputs.append(input)
    }
}

extension CaptureView: Inspectable {}
