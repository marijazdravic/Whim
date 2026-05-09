//
//  CaptureView.swift
//  WhimiOS
//
//  Created by Marija Zdravic on 10.05.2026..
//

import SwiftUI
import Whim

public struct CaptureView: View {
    private let viewModel: CaptureViewModel

    public init(viewModel: CaptureViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Text(viewModel.text)
    }
}
