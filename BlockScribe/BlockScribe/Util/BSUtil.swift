//
//  BSUtil.swift
//  BlockScribe
//
//  Created by Alex Lin on 12/4/24.
//

import Foundation
import os.log
import Security
import CryptoKit
import CoreImage.CIFilterBuiltins
import SwiftUI

struct Constants {
    static let KEY_ARTEFACTS = "artefacts"
    static let KEY_FILE_NAME_ENCRYPTED_ARTEFACTS = "encrypted.txt"
    static let KEY_ENCRYPT_KEY = "encrypt_key"
    static let KEY_SHARED_ENCRYPT_KEYS = "shared_encrypt_keys"
    
    static let KEY_FILE_NAME_DECRYPTED_ARTEFACTS = "decrypted.txt"
    
    static let KEY_SHARED_ARTEFACTS = "shared_artefacts"
    static let KEY_SHARED_ENCRYPTED_ARTEFACTS = "shared_encrypted_artefacts"
    
    static let KEY_KEYS = "keys"
    static let KEY_SHARED_KEYS = "shared_keys"
    
    static let KEY_INSCRIPTIONS = "inscriptions"
    
    static let KEY_PROFILE_IMAGE = "profile.jpg"
}

struct BSUtil {
    static let shared = BSUtil()
    
    //    func shareSecret(data: String, index: Int) -> [String] {
    //        let aesKey = SymmetricKey(size: .bits256)
    //        let base64Key = aesKey.withUnsafeBytes {
    //            Data(Array($0)).base64EncodedString()
    //        }
    //
    //        // Print the Base64 string
    //        print("Base64 Encoded SymmetricKey: \(base64Key)")
    //
    //        let loremIpsum = Data(_: [UInt8](base64Key.utf8))
    //
    //        print(loremIpsum.map { String(format: "0x%02x ", $0) }.joined())
    //        do {
    //            let secret = try Secret(data: loremIpsum, threshold: 2, shares: 3)
    //            let shares = try secret.split()
    //            print(shares[index].data.map { String(format: "0x%02x ", $0) }.joined())
    //
    //            let shares0ToBase64 = shares[index].data.base64EncodedString();
    //            print(shares0ToBase64)
    //
    //            let shares0FromBase64 = try shares0ToBase64.fromBase64();
    //            print(shares0FromBase64.map { String(format: "0x%02x ", $0) }.joined())
    //            let byteSize = shares0ToBase64.utf8.count
    //            print("Byte size of string: \(byteSize)")
    //
    //            print(shares[0].data.map { String(format: "0x%02x ", $0) }.joined())
    //            print(shares[1].data.map { String(format: "0x%02x ", $0) }.joined())
    //            print(shares[2].data.map { String(format: "0x%02x ", $0) }.joined())
    //
    //            let recon1  = try Secret.combine(shares: Array<Secret.Share>(shares[0...1]))
    //            print(recon1.map { String(format: "0x%02x ", $0) }.joined())
    //            if let recon1Str = String(bytes: recon1, encoding: .utf8) {
    //                print(recon1Str)
    //            }
    //
    //            let recon2  = try Secret.combine(shares: Array<Secret.Share>(shares[1...2]))
    //            print(recon2.map { String(format: "0x%02x ", $0) }.joined())
    //            print(recon2)
    //
    //            let recon3  = try Secret.combine(shares: Array<Secret.Share>([shares[0], shares[2]]))
    //            print(recon3.map { String(format: "0x%02x ", $0) }.joined())
    //            print(recon3)
    //
    //            return [shares0ToBase64]
    //        } catch {
    //        }
    //        return []
    //    }
    
    func generateQRCode(from string: String) -> Image? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        let transform = CGAffineTransform(scaleX: 10, y: 10) // Scale the QR code image
        
        if let outputImage = filter.outputImage?.transformed(by: transform) {
            let scaledImage = context.createCGImage(outputImage, from: outputImage.extent)
            let uiImage = UIImage(cgImage: scaledImage!)
            return Image(uiImage: uiImage)
        }
        return nil
    }
    
    func shareKeySecret() -> [String] {
        if let aesKeyData = retrieveFromKeychain(key: Constants.KEY_ENCRYPT_KEY) {
            do {
                let secret = try Secret(data: aesKeyData, threshold: 2, shares: 3)
                let shares = try secret.split()
                let shares1Base64 = shares[1].data.base64EncodedString();
                let shares2Base64 = shares[2].data.base64EncodedString();
                let sharedKeys = [shares1Base64, shares2Base64]
                if let data = BSUtil.shared.convertListToData(sharedKeys) {
                    let success = BSUtil.shared.saveToKeychain(data: data, for: Constants.KEY_SHARED_ENCRYPT_KEYS)
                    if (success) {
                        return sharedKeys
                    }
                }
                return []
            } catch {
            }
        }
        return []
    }
    
    func saveProfileImage(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 1.0) ?? image.pngData() else { return }
        
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access document directory")
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(Constants.KEY_PROFILE_IMAGE)
        try? data.write(to: fileURL)
    }
    
    func loadProfileImage() -> UIImage? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access document directory")
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(Constants.KEY_PROFILE_IMAGE)
        if let imageData = try? Data(contentsOf: fileURL) {
            return UIImage(data: imageData)
        }
        return nil
    }
    
    func encryptFile(at fileURL: URL) throws {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access document directory")
        }
        
        let aesKey = SymmetricKey(size: .bits256)
        let keyData = aesKey.withUnsafeBytes { Data(Array($0)) }
        let success = saveToKeychain(data: keyData, for: Constants.KEY_ENCRYPT_KEY)
        clearSharedEncryptKeys()
        
        if (success) {
            let fileData = try Data(contentsOf: fileURL)
            let sealedBoxEncrypt = try AES.GCM.seal(fileData, using: aesKey)
            if let encryptedData = sealedBoxEncrypt.combined {
                let encryptFileURL = documentsDirectory.appendingPathComponent(Constants.KEY_FILE_NAME_ENCRYPTED_ARTEFACTS)
                do {
                    try encryptedData.write(to: encryptFileURL)
                } catch {
                    print("Failed to write data: \(error)")
                }
            }
        }
    }
    
    func decryptFile() throws -> String? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access document directory")
        }
        
        if let aesKeyData = retrieveFromKeychain(key: Constants.KEY_ENCRYPT_KEY) {
            let encryptFileURL = documentsDirectory.appendingPathComponent(Constants.KEY_FILE_NAME_ENCRYPTED_ARTEFACTS)
            let encryptedData = try Data(contentsOf: encryptFileURL)
            let aesKey = SymmetricKey(data: aesKeyData)
            if let sealedBoxDecrypt = try? AES.GCM.SealedBox(combined: encryptedData) {
                if let decryptedData = try? AES.GCM.open(sealedBoxDecrypt, using: aesKey) {
                    let text = String(data:decryptedData, encoding: .utf8)
                    return text
                }
            }
        }
        return nil
    }
    
    func decryptFileWithSharedKeys(withSharedKeys sharedKeys: [String]) throws -> String? {
        
        let shareKey1 = try Secret.Share.init(data: sharedKeys[0].fromBase64())
        let shareKey2 = try Secret.Share.init(data: sharedKeys[1].fromBase64())
        
        let aesKeyData  = try Secret.combine(shares: Array<Secret.Share>([shareKey1, shareKey2]))
        let aesKey = SymmetricKey(data: aesKeyData)
        
        if let encryptedData = BSUtil.shared.retrieveFromKeychain(key: Constants.KEY_SHARED_ENCRYPTED_ARTEFACTS) {
            if let sealedBoxDecrypt = try? AES.GCM.SealedBox(combined: encryptedData) {
                if let decryptedData = try? AES.GCM.open(sealedBoxDecrypt, using: aesKey) {
                    let text = String(data:decryptedData, encoding: .utf8)
                    print(text)
                    return text
                }
            }
        }
        return nil
    }
    
    func fileSize(forURL url: URL) -> Int? {
        do {
            if (url.startAccessingSecurityScopedResource()) {
                // Get file attributes
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                // Extract file size from attributes
                if let fileSize = attributes[FileAttributeKey.size] as? Int {
                    return fileSize
                }
            } else {
                return 0
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        return nil
    }
    
    func apiGet(from url: String) async throws -> Data {
        // Ensure the URL is valid
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        // Perform the network request using URLSession
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Ensure the response is valid and within the expected range
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
    
    func createInscribeInvoice(wallet walletAddress: String, completion: @escaping (Result<InscribeResponse, Error>) -> Void) {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access document directory")
        }
        
        let encryptFileURL = documentsDirectory.appendingPathComponent(Constants.KEY_FILE_NAME_ENCRYPTED_ARTEFACTS)
        if let encryptedData = try? Data(contentsOf: encryptFileURL) {
            let inscribeText = encryptedData.base64EncodedString()
            
            let backendUrl = URL(string: "https://api.ordinalsbot.com/textorder")!
            var request = URLRequest(url: backendUrl)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "texts": [inscribeText],
                "receiveAddress": walletAddress,
                "fee": "3"
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    print("No data")
                    return
                }
                
//                if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {                    
//                    // Convert JSON object to JSON string
//                    if let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) {
//                        if let jsonString = String(data: jsonData, encoding: .utf8) {
//                            print("JSON String: \(jsonString)")
//                        } else {
//                            print("Failed to convert JSON data to string")
//                        }
//                    }
//                }
                
                // Parse the JSON data
                do {
                    let responseObject = try JSONDecoder().decode(InscribeResponse.self, from: data)
                    completion(.success(responseObject))
                } catch {
                    completion(.failure(error))
                }
                
            })
            task.resume()
        }
    }
    
    func deleteUser(userId: String) async throws -> (Data?, URLResponse?) {
        do {
            let (data, response) = try await deleteRequest(urlString: "https://blockscribe.kinde.com/api/v1/user?id=\(userId)")
            return (data, response)
        }catch{
            return (nil, nil)
        }
    }
    
    func postRequest(urlString: String, body: [String: Any]) async throws -> (Data, URLResponse) {
        // Ensure the URL is valid
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // Convert the body dictionary to JSON data
        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
        
        // Create a URLRequest object
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Perform the network request
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, response)
    }
    
    func deleteRequest(urlString: String) async throws -> (Data?, URLResponse?) {
        // Ensure the URL is valid
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        if let access_token = try await getKindeOAuthToken(clientId: "2bfebb15bf5646af94ed8bbd69b86e83", clientSecret: "IEE2IOelWAFrKpsMi25OsHBhJzjvbsMW192KmEw7emJF5F80hO", audience: "https://blockscribe.kinde.com/api", domain: "blockscribe") {
            
            // Create a URLRequest object
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(access_token)", forHTTPHeaderField: "Authorization")
            
            // Perform the network request
            let (data, response) = try await URLSession.shared.data(for: request)
            return (data, response)
        }
        return(nil, nil)
    }
    
    func getKindeOAuthToken(clientId: String, clientSecret: String, audience: String, domain: String) async throws -> String? {
        // Construct the URL for the token endpoint
        let tokenUrl = URL(string: "https://\(domain).kinde.com/oauth2/token")!
        
        // Prepare the request body with necessary parameters
        let bodyParams = [
            "grant_type": "client_credentials",
            "client_id": clientId,
            "client_secret": clientSecret,
            "audience": audience
        ]
        
        // Convert body parameters to a format that can be sent in the request
        let bodyString = bodyParams.map { "\($0.key)=\($0.value)" }
                                   .joined(separator: "&")
        
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyString.data(using: .utf8)
        
        // Perform the network request asynchronously
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the response and try to parse the access token
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            let accessToken = json?["access_token"] as? String            
            print("Access token \(accessToken)")
            return accessToken
        } else {
            print("Failed to get token: HTTP status \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            return nil
        }
    }
    
    
    func convertListToData<T: Encodable>(_ list: [T]) -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(list)
    }
    
    func convertDataToList<T: Decodable>(_ data: Data) -> [T]? {
        let decoder = JSONDecoder()
        return try? decoder.decode([T].self, from: data)
    }
    
    func saveToKeychain(data: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary) // Remove any existing item with the same key
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func retrieveFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject? = nil
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        } else {
            return nil
        }
    }
    
    func clearData() {
        let artefacts: [Artefact] = []
        if let data = BSUtil.shared.convertListToData(artefacts) {
            _ = BSUtil.shared.saveToKeychain(data: data, for: Constants.KEY_ARTEFACTS)
        }
        
        if let data = BSUtil.shared.convertListToData(artefacts) {
            _ = BSUtil.shared.saveToKeychain(data: data, for: Constants.KEY_SHARED_ARTEFACTS)
        }
        
        let keys: [Key] = []
        if let data = BSUtil.shared.convertListToData(keys) {
            _ = BSUtil.shared.saveToKeychain(data: data, for: Constants.KEY_KEYS)
        }
        
        if let data = BSUtil.shared.convertListToData(keys) {
            _ = BSUtil.shared.saveToKeychain(data: data, for: Constants.KEY_SHARED_KEYS)
        }
        
        let inscriptions: [Inscription] = []
        if let data = BSUtil.shared.convertListToData(inscriptions) {
            _ = BSUtil.shared.saveToKeychain(data: data, for: Constants.KEY_INSCRIPTIONS)
        }
        
        clearSharedEncryptKeys()
    }
    
    func clearSharedEncryptKeys() {
        let sharedEncryptKeys: [String] = []
        if let data = BSUtil.shared.convertListToData(sharedEncryptKeys) {
            _ = BSUtil.shared.saveToKeychain(data: data, for: Constants.KEY_SHARED_ENCRYPT_KEYS)
        }
    }
    
    func openURL(_ urlString: String) {
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }
    
    func updateColorScheme(_ colorScheme: ColorScheme) {
        UINavigationBar.appearance().backgroundColor = UIColor(named: "MainBgColor")
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor(named: "MainTextColor")!]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(named: "MainTextColor")!]
    }
}
