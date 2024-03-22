//
//  AlertBanner.swift
//  WeSpot
//
//  Created by Thomas Segkoulis on 09.12.23.
//

import SwiftUI

struct AlertBanner: View {

	var model: Model
	
    var body: some View {
		HStack(alignment: .center, spacing: 0) {
			HStack(alignment: .center, spacing: 12) {
				model.image
					.resizable()
					.frame(width: 24, height: 24)
					.foregroundColor(Color.blue)
				Text(model.title)
					.lineLimit(2)
					.foregroundColor(Color.black)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(.trailing, 16)
			if let buttonTitle = model.buttonTitle {
				HStack {
					Spacer()
					Button(action: {
						model.buttonAction?()
					}, label: {
						Text(buttonTitle)
							.foregroundColor(Color.blue)
							.frame(height: 32)
							.padding(.horizontal, 16)
					})
					.layoutPriority(1)
				}
				.frame(maxWidth: 120)
			}
		}
		.padding(.leading, 16)
		.frame(maxWidth: .infinity, minHeight: 60)
		.background(Color.blue)
		.clipShape(RoundedRectangle(cornerRadius: 10.0, style: .circular))
    }
}

extension AlertBanner {
	struct Model: Identifiable {
		var id: String = UUID().uuidString
		var image: Image
		var title: String
		var buttonTitle: String?
		var buttonAction: (() -> Void)?
	}
}

// MARK: - Previews

fileprivate struct CustomScreen<T: AlertDisplaying>: View {

	@State private var showView: Bool = false
	@State private var showViewNew: Bool = false
	
	@State var counter: Int = 1
	@ObservedObject var viewModel: T = .init(numOfConcurrentAlerts: 3, alertDuration: 2)

	init() {
	}

	var body: some View {
		ZStack(alignment: .top) {

		  VStack {
			Spacer()
			Button("Show Alert") {
				try? viewModel.schedule(alert: .init(image: Image.init(systemName: "checkmark.circle.fill"), title: "Title - \(counter)", buttonTitle: "press me"))
				counter += 1
			}
			  Spacer()
			  Button("Show Additional Alert") {
				withAnimation { showViewNew.toggle() }
			  }
			Spacer()
		  }
		}
		.frame(maxWidth: .infinity)
		.alertBannerDisplaying(scheduler: viewModel)
	}
	
}

#Preview {
	ZStack {
		CustomScreen<AlertQueueScheduler>()
			.environment(\.sizeCategory, .extraExtraExtraLarge)
	}
}

