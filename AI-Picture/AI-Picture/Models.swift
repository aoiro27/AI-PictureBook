//
//  Models.swift
//  AIPictureBook
//
//  Created by Yuki Usui on 2025/07/17.
//

import Foundation

struct BookPage: Codable {
    let pageNumber: Int
    let text: String
    let illustrationIdea: String
    var imageUrl: String?
    var imageLoadingStatus: ImageLoadingStatus = .loading
    
    enum CodingKeys: String, CodingKey {
        case pageNumber, text, illustrationIdea, imageUrl
    }
    
    init(pageNumber: Int, text: String, illustrationIdea: String, imageUrl: String?) {
        self.pageNumber = pageNumber
        self.text = text
        self.illustrationIdea = illustrationIdea
        self.imageUrl = imageUrl
        self.imageLoadingStatus = imageUrl != nil ? .success : .loading
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pageNumber = try container.decode(Int.self, forKey: .pageNumber)
        text = try container.decode(String.self, forKey: .text)
        illustrationIdea = try container.decode(String.self, forKey: .illustrationIdea)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        imageLoadingStatus = imageUrl != nil ? .success : .loading
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pageNumber, forKey: .pageNumber)
        try container.encode(text, forKey: .text)
        try container.encode(illustrationIdea, forKey: .illustrationIdea)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
    }
}

struct SavedBook: Codable, Identifiable {
    let id = UUID()
    let title: String
    let createdAt: Date
    let pages: [BookPage]
    
    var pageCount: Int {
        return pages.count
    }
}

enum ImageLoadingStatus {
    case loading
    case success
    case failed
} 