//
//  zkp_client_demoApp.swift
//  zkp-client-demo
//
//  Created by Thomas Segkoulis on 25.01.24.
//

import SwiftUI
import zkp_client

@main
struct zkp_client_demoApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
	@State var viewModel = ContentViewModel()
    var body: some Scene {
        WindowGroup {
			ContentView(viewModel: viewModel)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		print("App Did Launch!")
		let deviceID = UIDevice.current.identifierForVendor?.uuidString
		print("Vendor id: \(deviceID)")
		return true
	}
	
	func application(_ application: UIApplication,
						 open url: URL,
						 options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		print("--- Openning url\(url)")
		return true
	}
	
	func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
		print("--- Openning url\(url)")
		
		return true
	}
	
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		let sceneConfig: UISceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
		sceneConfig.delegateClass = SceneDelegate.self
		return sceneConfig
	}
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
	
	var window: UIWindow?
	var authenticator: BindingAuthenticator?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let _ = (scene as? UIWindowScene) else { return }
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		
	}
	
	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		print("-scene open url: \(URLContexts.first?.url)")
		
		guard let url = URLContexts.first?.url else {
			return
		}
		let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
		print("urlComponents: \(urlComponents)")
		print("queries: \(urlComponents?.queryItems)")

		guard 
			let queryItems = urlComponents?.queryItems,
			queryItems.count == 2,
			let serviceID = queryItems.first(where: {
				$0.name == "serviceID"
			})?.value,
			let characteristicID = queryItems.first(where: {
				$0.name == "characteristicID"
			})?.value
		else {
			return
		}
		let client = try! ZKPClient(flavor: .fiatShamir(config: .init(coprimeWidth: 2048)),
							   apiConfig: APIConfiguration(baseWSURL: "ws://192.168.2.111:8011", baseHTTPURL: "https://192.168.2.111:8011"),
										userID: "thomas111")
		self.authenticator = BindingAuthenticator(serviceID: serviceID, characteristicID: characteristicID, client: client)
	}
}

/// 192.168.178.52:8004
/// "ws://33fc-2003-ed-5f26-b800-75c5-b5d4-a4f9-d3ad.ngrok-free.app"
/// https://33fc-2003-ed-5f26-b800-75c5-b5d4-a4f9-d3ad.ngrok-free.app"
