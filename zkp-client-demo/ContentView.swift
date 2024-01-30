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
	var userID = "tom24"
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
				do {
					try self.viewModel.client?.sendAuthentication(payload: "some-dummy-payload".data(using: .utf8)!,
																userID: userID)
				} catch {
					print("error registering: \(error)")
				}
			}
			.frame(width: 200, height: 60)

			Button("register") {
				Task {
					do {
						try self.viewModel.client?.sendRegistration(payload: "some-dummy-payload".data(using: .utf8)!,
																	userID: userID)
					} catch {
						print("error registering: \(error)")
					}
				}
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
			self.client = try ZKPClient(flavor: .fiatShamir(config: .init(coprimeWidth: 200)),
										config: .init(baseURL: "ws://192.168.178.52:8012"))
		} catch {
			print("fail to create the client: \(error.localizedDescription)")
		}
	}
}
