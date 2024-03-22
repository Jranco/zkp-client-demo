//
//  ContentView.swift
//  zkp-client-demo
//
//  Created by Thomas Segkoulis on 25.01.24.
//

import SwiftUI
import zkp_client
import AuthenticationServices
import SwiftCBOR
import CoreImage.CIFilterBuiltins

public struct QRCodeView: View {
	let context = CIContext()
	let filter = CIFilter.qrCodeGenerator()
	
	func generateQRCode(from string: String) -> UIImage {
		filter.message = Data(string.utf8)

		if let outputImage = filter.outputImage {
			if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
				return UIImage(cgImage: cgImage)
			}
		}

		return UIImage(systemName: "xmark.circle") ?? UIImage()
	}

	public init() {}

	public var body: some View {
		Image(uiImage: generateQRCode(from: "device-binding://somepath/"))
			.interpolation(.none)
			.resizable()
			.scaledToFit()
			.frame(width: 200, height: 200)
	}
}

struct ContentView: View {
	
	@ObservedObject var viewModel: ContentViewModel
	init() {
		self.viewModel = ContentViewModel()
	}

    var body: some View {
		NavigationView {
			
			VStack {
				QRCodeView()
					.frame(width: 200, height: 200)
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
				
				Button("auth") {
					viewModel.didTapPasskey()
				}
				.frame(width: 200, height: 60)
				
				NavigationLink("Bind new device") {
					DeviceBindingView(delegate: nil, devicePK: try! viewModel.client!.getDevicePublicKey())
				}
			}
			.padding()
		}
    }
}

#Preview {
    ContentView()
}

class ContentViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
	
	static var userID = "tom42"
	
	@Published var client: ZKPClient?
	let authPresentationProvider = AuthorizationPresentationContextProvider()
	override init() {
		super.init()
		do {
			self.client = try ZKPClient(flavor: .fiatShamir(config: .init(coprimeWidth: 256)),
										apiConfig: APIConfiguration(baseWSURL: "ws://192.168.178.52:8013", baseHTTPURL: "http://192.168.178.52:8013"),
										userID: Self.userID)
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
	
	func didTapPasskey() {
		let challenge: Data! = "super-challenge".data(using: .utf8)
		let userID: Data! = "segk@gmail.com".data(using: .utf8)
		let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "164f-2003-ed-5f07-cf00-5589-d72a-cb0-6c6f.ngrok-free.app")
		let platformKeyRequest = platformProvider.createCredentialRegistrationRequest(challenge: challenge, name: "Thomas Segkoulis", userID: userID)
		let authController = ASAuthorizationController(authorizationRequests: [platformKeyRequest])
		authController.delegate = self
		authController.presentationContextProvider = authPresentationProvider
		authController.performRequests()
	}
	
	// MARK: - ASAuthorizationControllerDelegate
	
	func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
		if let auth =  authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
			let json = auth.rawClientDataJSON
			print("json: \(String(data: json, encoding: .utf8)!)")
//			print("credentialID: \(String(data: auth.credentialID, encoding: .utf8)!)")
			
			if let attestationObject = auth.rawAttestationObject {
			
				let decodedAtt = decodeRawAttestationObject(rawAttestationObject: [UInt8](attestationObject))
				print("decodedAtt: \(decodedAtt)")
				let att64 = attestationObject.base64EncodedString() // base64EncodedString()
				
				let clientData = auth.rawClientDataJSON.base64EncodedString()

			}
		} else if let auth =  authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
//			print("auth: \(auth.credentialID)")
			
		}
	}

	func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
		print("--- did fail: \(error)")
	}
	
	func decodeRawAttestationObject(rawAttestationObject: [UInt8]) -> [String: CBOR] {
		do {
			// Parse the rawAttestationObject from [UInt8] to a CBOR structure
			let cborObject = try CBOR.decode(rawAttestationObject)
			
			// Check if the CBOR object is a map (dictionary)
			guard case let CBOR.map(mapData) = cborObject! else {
				print("Error: Raw attestation object is not a map")
				return [:]
			}
			
			// Convert CBOR map to a Swift dictionary
			var attestationObject: [String: CBOR] = [:]
			for (key, value) in mapData {
				guard case let CBOR.utf8String(keyString) = key else {
					print("Error: Unexpected key type")
					continue
				}
				attestationObject[keyString] = value
			}
			
			if let authenticatorData = mapData["authData"],
					case let CBOR.byteString(authenticatorDataBytes) = authenticatorData {
					 // Parse the authenticator data to extract the public key
					 let publicKey = extractPublicKey(from: authenticatorDataBytes)
					 print("Public Key: \(publicKey)")
				let publicKeyBase64String = publicKeyToBase64String(publicKey: publicKey!)
				print("Public Key Base64 String: \(publicKeyBase64String)")
				 }
			
			return attestationObject
		} catch {
			print("Error decoding raw attestation object: \(error)")
			return [:]
		}
	}
	
	// Function to extract the public key from the authenticator data
	func extractPublicKey(from authenticatorData: [UInt8]) -> [UInt8]? {
		// Implement your logic to parse the authenticator data and extract the public key
		// This might involve decoding CBOR structures and extracting relevant fields
		// For example, you might look for COSE_Key structures within the authenticator data
		// and extract the public key bytes from there.
		
		// Sample implementation:
		// Example: If the public key is located at a specific offset within the authenticator data
		let publicKeyOffset = 64 // Adjust this value based on your authenticator data format
		let publicKeyBytes = Array(authenticatorData[publicKeyOffset...])
		return publicKeyBytes
	}
	
	func publicKeyToBase64String(publicKey: [UInt8]) -> String {
		let publicKeyData = Data(publicKey)
		let base64String = publicKeyData.base64EncodedString()
		return base64String
	}
}

class AuthorizationPresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
	func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
		// Return the presentation anchor for the authorization controller
		// Typically, you return the window of the current scene
		UIApplication.shared.windows.first!
	}
}
