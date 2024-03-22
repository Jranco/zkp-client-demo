//
//  AlertBannerModifier.swift
//  zkp-client-demo
//
//  Created by Thomas Segkoulis on 06.03.24.
//

import SwiftUI

struct AlertBannerModifier<T: AlertDisplaying>: ViewModifier {

	@ObservedObject var scheduler: T
	@State private var offsetY: CGFloat = 0

	func body(content: Content) -> some View {
		content.overlay {
			VStack {
				Spacer()
				VStack(spacing: 16) {
					ForEach(scheduler.queueFired.list) { item in
						AlertBanner(model: item)
							.transition(.asymmetric(
								insertion: scheduler.queueFired.list.count == 1 ? .opacity : .move(edge: .bottom),
							  removal: .opacity
							))
					}
				}
				.padding(.vertical, 20)
				.padding(.horizontal, 16)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.offset(x: 0, y:  offsetY)
			.highPriorityGesture(
				DragGesture()
					.onChanged { gesture in
						guard gesture.translation.height >= 0 else {
							return
						}
						scheduler.pause()
						self.offsetY = gesture.translation.height
					}
					.onEnded { _ in
						withAnimation {
							self.offsetY = 0
							scheduler.dismissAll()
						}
					}
			)
		}
	}
}

