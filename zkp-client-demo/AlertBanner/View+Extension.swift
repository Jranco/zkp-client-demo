//
//  View+Extension.swift
//  zkp-client-demo
//
//  Created by Thomas Segkoulis on 06.03.24.
//

import SwiftUI

extension View {
	func alertBannerDisplaying<T: AlertDisplaying>(scheduler: T) -> some View {
		self.modifier(AlertBannerModifier(scheduler: scheduler))
	}
}
