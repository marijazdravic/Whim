//
//  CaptureView.swift
//  WhimiOS
//
//  Created by Marija Zdravic on 10.05.2026..
//

import SwiftUI
import Whim

public struct CaptureView: View {
    @Bindable private var viewModel: CaptureViewModel

    public init(viewModel: CaptureViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        TextField("What's on your mind?", text: textBinding)
    }
}

private extension CaptureView {
    var textBinding: Binding<String> {
        Binding {
            viewModel.text
        } set: { newValue in
            viewModel.updateText(newValue)
        }
    }
}
