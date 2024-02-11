//
//  ContentView.swift
//  zkp-client-demo
//
//  Created by Thomas Segkoulis on 25.01.24.
//

import SwiftUI
import zkp_client

struct ContentView: View {
	
	@ObservedObject var viewModel: ContentViewModel
	init() {
		self.viewModel = ContentViewModel()
	}

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")

			Button("login") {
				viewModel.didTapLogin()
			}
			.frame(width: 200, height: 60)

			Button("register") {
				viewModel.didTapRegister()
			}
			.frame(width: 200, height: 60)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

class ContentViewModel: ObservableObject {
	@Published var client: ZKPClient?

	init() {
		do {
			self.client = try ZKPClient(flavor: .fiatShamir(config: .init(coprimeWidth: 256)),
										apiConfig: APIConfiguration(baseWSURL: "ws://192.168.178.52:8012", baseHTTPURL: "http://192.168.178.52:8012"),
										userID: "tom42")
		} catch {
			print("fail to create the client: \(error.localizedDescription)")
		}
	}
	
	func didTapLogin() {
		Task {
			do {
				try await client?.sendAuthentication(payload: "some-dummy-payload".data(using: .utf8)!)
			} catch {
				print("error registering: \(error)")
			}
		}
	}
	
	func didTapRegister() {
		Task {
			do {
				try await client?.sendRegistration(payload: "some-dummy-payload".data(using: .utf8)!)
			} catch {
				print("error registering: \(error)")
			}
		}
	}
}
