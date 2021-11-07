//
//  ImageStorage.swift
//  VirtualTourist
//
//  Created by Anton Kinstler on 11.08.2021.
//
import UIKit

final class ImageStorage {
    
    private let fileManager: FileManager
    private let path: String
    
    init() throws {
        
        self.fileManager = FileManager.default
        let url = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let path = url.appendingPathComponent("VirtualTourist", isDirectory: true).path
        self.path = path
        
        try createDirectory()
        try setDirectoryAttributes([.protectionKey: FileProtectionType.complete])
    }
    
    func setImage(image: Data, forKey key: String) {
        let filePath = makeFilePath(for: key)
        fileManager.createFile(atPath: filePath, contents: image, attributes: nil)
    }
    
    func image(forKey key: String) throws -> UIImage {
        let filePath = makeFilePath(for: key)
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        guard let image = UIImage(data: data) else {
            throw Error.invalidImage
        }
        
        return image
    }
}

private extension ImageStorage {
    
    func setDirectoryAttributes(_ attributes: [FileAttributeKey: Any]) throws {
        try fileManager.setAttributes(attributes, ofItemAtPath: path)
    }
    
    func makeFileName(for key: String) -> String {
        let fileExtension = URL(fileURLWithPath: key).pathExtension
        return fileExtension.isEmpty ? key : "\(key).\(fileExtension)"
    }
    
    func makeFilePath(for key: String) -> String {
        return "\(path)/\(makeFileName(for: key))"
    }
    
    func createDirectory() throws {
        guard !fileManager.fileExists(atPath: path) else {
            return
        }
        
        try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    }
}

private extension ImageStorage {
    
    enum Error: Swift.Error {
        case invalidImage
    }
}
