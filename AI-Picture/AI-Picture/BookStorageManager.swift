//
//  BookStorageManager.swift
//  AIPictureBook
//
//  Created by Yuki Usui on 2025/07/17.
//

import Foundation

class BookStorageManager: ObservableObject {
    @Published var savedBooks: [SavedBook] = []
    @Published var errorMessage: String? = nil
    
    private let maxBooks = 10
    private let userDefaultsKey = "SavedBooks"
    
    init() {
        loadSavedBooks()
    }
    
    func saveBook(_ pages: [BookPage]) -> Bool {
        guard !pages.isEmpty else { return false }
        
        // 保存容量チェック
        if savedBooks.count >= maxBooks {
            errorMessage = "保存できる絵本は\(maxBooks)冊までです。古い絵本を削除してください。"
            return false
        }
        
        // より意味のあるタイトルを生成（最初のページのテキストから）
        let firstPageText = pages.first?.text ?? ""
        let title = firstPageText.count > 20 ? String(firstPageText.prefix(20)) + "..." : firstPageText
        let finalTitle = title.isEmpty ? "新しい絵本" : title
        
        let savedBook = SavedBook(
            title: finalTitle,
            createdAt: Date(),
            pages: pages
        )
        
        savedBooks.append(savedBook)
        saveBooksToUserDefaults()
        
        print("絵本を保存しました: タイトル=\(finalTitle), ページ数=\(pages.count)")
        return true
    }
    
    func loadBook(_ book: SavedBook) -> [BookPage] {
        return book.pages
    }
    
    func deleteBook(_ book: SavedBook) {
        savedBooks.removeAll { $0.id == book.id }
        saveBooksToUserDefaults()
        print("絵本を削除しました: タイトル=\(book.title)")
    }
    
    func deleteOldestBook() -> Bool {
        if let oldestBook = savedBooks.min(by: { $0.createdAt < $1.createdAt }) {
            savedBooks.removeAll { $0.id == oldestBook.id }
            saveBooksToUserDefaults()
            print("古い絵本を削除しました: タイトル=\(oldestBook.title)")
            return true
        }
        return false
    }
    
    func canSaveBook() -> Bool {
        return savedBooks.count < maxBooks
    }
    
    func getOldestBook() -> SavedBook? {
        return savedBooks.min(by: { $0.createdAt < $1.createdAt })
    }
    
    private func loadSavedBooks() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let books = try? JSONDecoder().decode([SavedBook].self, from: data) {
            savedBooks = books
            print("保存済み絵本を読み込みました: \(books.count)冊")
            for (index, book) in books.enumerated() {
                print("絵本\(index + 1): タイトル=\(book.title), ページ数=\(book.pageCount), 作成日=\(book.createdAt)")
            }
        } else {
            print("保存済み絵本の読み込みに失敗しました")
        }
    }
    
    private func saveBooksToUserDefaults() {
        if let data = try? JSONEncoder().encode(savedBooks) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
} 