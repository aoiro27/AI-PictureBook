//
//  ContentView.swift
//  AIPictureBook
//
//  Created by Yuki Usui on 2025/07/17.
//

import SwiftUI
import AVFoundation

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

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) {
        stopSpeaking()
        
        let utterance = AVSpeechUtterance(string: text)
        // Kyokoを明示的に指定
        utterance.voice = AVSpeechSynthesisVoice(identifier: "com.apple.ttsbundle.Kyoko-premium")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.8
        utterance.postUtteranceDelay = 0.5
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
        
    // AVSpeechSynthesizerDelegate Delegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}

struct ContentView: View {
    @State private var bookPages: [BookPage] = []
    @State private var currentPage: Int = 0
    @State private var isLoading: Bool = false
    @State private var isGeneratingImages: Bool = false
    @State private var errorMessage: String? = nil
    @StateObject private var speechManager = SpeechManager()
    @State private var savedBooks: [SavedBook] = []
    @State private var showingMainMenu: Bool = true
    @State private var showingDeleteAlert: Bool = false
    @State private var showingStorageAlert: Bool = false
    @State private var bookToDelete: SavedBook? = nil
    @State private var pageCount: Int = 3
    @State private var showingPageCountInput: Bool = false
    
    var body: some View {
        ZStack {
            // 背景画像
            Image("bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
            
            // 背景オーバーレイ（テキストの可読性向上）
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
            
            if showingMainMenu {
                // メインメニュー
                mainMenuView
            } else if showingPageCountInput {
                // ページ数入力画面
                pageCountInputView
            } else if bookPages.isEmpty || isGeneratingImages {
                // 初期画面または画像生成中
                VStack(spacing: 30) {
                    if isGeneratingImages {
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                        
                        Text("画像を生成中...")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(1.5)
                    } else {
                        Image(systemName: "book.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Button(action: generateImage) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("絵本を生成")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(width: 200, height: 50)
                        .background(isLoading ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                        .disabled(isLoading)
                    }
                }
            } else {
                // 絵本表示画面
                VStack(spacing: 0) {
                    // ヘッダー
                    HStack {
                        Button(action: returnToMainMenu) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                Text("戻る")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                        }
                        .padding(.leading)
                        
                        Spacer()
                        
                        Text("ページ \(currentPage + 1) / \(bookPages.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: saveBook) {
                            HStack(spacing: 5) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title2)
                                Text("保存")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                        }
                        .padding(.trailing)
                    }
                    .padding(.top)
                    
                    // 絵本ページ
                    VStack(spacing: 20) {
                        // 画像表示
                        if let imageUrl = bookPages[currentPage].imageUrl,
                           let imageURL = URL(string: imageUrl) {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(height: 300)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 350, maxHeight: 300)
                                        .cornerRadius(15)
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.system(size: 100))
                                        .foregroundColor(.gray)
                                        .frame(height: 300)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 300)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                )
                        }
                        
                        // テキスト表示
                        Text(bookPages[currentPage].text)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .frame(minHeight: 80)
                    }
                    .padding()
                    
                    // ページ送りボタン
                    HStack(spacing: 40) {
                        Button(action: previousPage) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(currentPage > 0 ? .white : .gray)
                        }
                        .disabled(currentPage <= 0)
                        
                        Button(action: nextPage) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(currentPage < bookPages.count - 1 ? .white : .gray)
                        }
                        .disabled(currentPage >= bookPages.count - 1)
                    }
                    .padding(.bottom)
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
            }
        }
        .onAppear {
            loadSavedBooks()
        }
        .alert("保存済み絵本を削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) {
                deleteBook()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("「\(bookToDelete?.title ?? "")」を削除しますか？")
        }
        .alert("保存容量の上限", isPresented: $showingStorageAlert) {
            Button("古い絵本を削除", role: .destructive) {
                deleteOldestBook()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("保存できる絵本は10冊までです。古い絵本を削除して新しい絵本を保存しますか？")
        }
    }
    
    private var mainMenuView: some View {
        VStack(spacing: 30) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
            
            Text("Original Picture Book")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                Button(action: { showingPageCountInput = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("新しい絵本を作る")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 250, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
                
                if !savedBooks.isEmpty {
                    Text("保存済みの絵本")
                        .font(.headline)
                        .padding(.top, 20)
                    
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(savedBooks) { book in
                                savedBookRow(book)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 400)
                }
            }
        }
        .padding()
    }
    
    private func savedBookRow(_ book: SavedBook) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(book.pageCount)ページ • \(formatDate(book.createdAt))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                Button(action: { loadBook(book) }) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
                
                Button(action: { 
                    bookToDelete = book
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
    }
    
    private var pageCountInputView: some View {
        VStack(spacing: 30) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
            
            Text("ページ数を選択")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                Text("絵本のページ数を選択してください")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 20) {
                    Button(action: { if pageCount > 1 { pageCount -= 1 } }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                            .foregroundColor(pageCount > 1 ? .blue : .gray)
                    }
                    .disabled(pageCount <= 1)
                    
                    Text("\(pageCount)ページ")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(minWidth: 100)
                    
                    Button(action: { if pageCount < 10 { pageCount += 1 } }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(pageCount < 10 ? .blue : .gray)
                    }
                    .disabled(pageCount >= 10)
                }
                
                Text("1〜10ページの間で選択できます")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 20) {
                    Button(action: { showingPageCountInput = false }) {
                        Text("キャンセル")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(width: 120, height: 50)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                    
                    Button(action: startBookGeneration) {
                        Text("作成開始")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(width: 120, height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                }
            }
        }
        .padding()
    }
    
    func generateImage() {
        isLoading = true
        errorMessage = nil
        
        // 動的にプロンプトを生成
        let dynamicPrompt = generatePrompt()
        
        // 最初のリクエスト: 新しいAPIエンドポイント
        guard let firstUrl = URL(string: "https://ai-plot-488889291017.asia-northeast1.run.app") else { return }
        let firstBody: [String: Any] = ["prompt": dynamicPrompt]
        let firstJsonData = try? JSONSerialization.data(withJSONObject: firstBody)
        var firstRequest = URLRequest(url: firstUrl)
        firstRequest.httpMethod = "POST"
        firstRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        firstRequest.httpBody = firstJsonData
        
        URLSession.shared.dataTask(with: firstRequest) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "最初のリクエストエラー: \(error.localizedDescription)"
                    isLoading = false
                    return
                }
                                if let responseString = String(data: data!, encoding: .utf8) {
                    print("最初のリクエストレスポンス:", responseString)
                    
                    // JSONレスポンスを解析
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data!) as? [String: Any],
                           let answer = json["answer"] as? String {
                            
                            // ```json と ``` を除去してJSON部分を抽出
                            let jsonStart = answer.range(of: "```json\n")
                            let jsonEnd = answer.range(of: "\n```")
                            
                            if let start = jsonStart, let end = jsonEnd {
                                let jsonString = String(answer[start.upperBound..<end.lowerBound])
                                
                                if let jsonData = jsonString.data(using: .utf8),
                                   let pages = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {
                                    
                                    print("\n=== 絵本の内容 ===")
                                    var tempPages: [BookPage] = []
                                    for page in pages {
                                        if let pageNum = page["page"] as? Int,
                                           let pageText = page["PageText"] as? String,
                                           let illustrationIdea = page["IllustrationIdea"] as? String {
                                            print("ページ \(pageNum):")
                                            print("  テキスト: \(pageText)")
                                            print("  イラスト案: \(illustrationIdea)")
                                            print("")
                                            
                                            let bookPage = BookPage(
                                                pageNumber: pageNum,
                                                text: pageText,
                                                illustrationIdea: illustrationIdea,
                                                imageUrl: nil
                                            )
                                            tempPages.append(bookPage)
                                        }
                                    }
                                    
                                    // ページを順番に並び替えて保存
                                    tempPages.sort { $0.pageNumber < $1.pageNumber }
                                    self.bookPages = tempPages
                                    self.currentPage = 0
                                    self.isGeneratingImages = true
                                    
                                    // 各ページの画像を生成
                                    let constPrefix = "Shiki is a five-year-old human boy, and Shiro is his one-year-old little sister."
                                    for (index, page) in tempPages.enumerated() {
                                        self.executeSecondRequest(prompt: constPrefix + page.illustrationIdea, pageIndex: index, retryCount: 0)
                                    }
                                    
                                    // 最初のページの音声読み上げを開始
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        self.startSpeech()
                                    }
                                }
                            }
                        }
                    } catch {
                        print("JSON解析エラー:", error)
                    }
                } else {
                    print("最初のリクエストレスポンス: デコードできませんでした")
                }
            }
        }.resume()
    }
    
    private func executeSecondRequest(prompt: String, pageIndex: Int, retryCount: Int) {
        guard let url = URL(string: "https://ai-picture-488889291017.asia-northeast1.run.app") else { return }
        let body: [String: Any] = ["prompt": prompt]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.handleImageRequestError(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount, error: error)
                    return
                }
                
                // HTTPステータスコードをチェック
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 500 && retryCount < 3 {
                        // 500エラーの場合、30秒待ってから再試行
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                            self.executeSecondRequest(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount + 1)
                        }
                        return
                    }
                }
                
                guard let data = data else {
                    self.handleImageRequestError(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount, error: nil)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let url = json["image_url"] as? String {
                        // 対応するページの画像URLを更新
                        if pageIndex < self.bookPages.count {
                            self.bookPages[pageIndex].imageUrl = url
                            self.bookPages[pageIndex].imageLoadingStatus = .success
                        }
                    } else {
                        self.handleImageRequestError(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount, error: nil)
                    }
                } catch {
                    self.handleImageRequestError(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount, error: error)
                }
                
                // すべての画像の生成状況をチェック
                self.checkAllImagesGenerated()
            }
        }.resume()
    }
    
    private func handleImageRequestError(prompt: String, pageIndex: Int, retryCount: Int, error: Error?) {
        if retryCount < 3 {
            // 30秒待ってから再試行
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                self.executeSecondRequest(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount + 1)
            }
        } else {
            // 3回試行しても失敗した場合
            if pageIndex < self.bookPages.count {
                self.bookPages[pageIndex].imageLoadingStatus = .failed
            }
            self.errorMessage = "画像生成に失敗しました (ページ\(pageIndex + 1))"
            self.checkAllImagesGenerated()
        }
    }
    
    private func checkAllImagesGenerated() {
        let allCompleted = bookPages.allSatisfy { page in
            page.imageLoadingStatus == .success || page.imageLoadingStatus == .failed
        }
        
        if allCompleted {
            isGeneratingImages = false
            isLoading = false
        }
    }
    
    private func startSpeech() {
        guard !bookPages.isEmpty && currentPage < bookPages.count else { return }
        
        let text = bookPages[currentPage].text
        speechManager.speak(text)
    }
    
    private func stopSpeech() {
        speechManager.stopSpeaking()
    }
    
    // MARK: - 保存・読み込み・削除機能
    
    private func createNewBook() {
        showingPageCountInput = true
    }
    
    private func startBookGeneration() {
        showingPageCountInput = false
        bookPages = []
        currentPage = 0
        isLoading = false
        isGeneratingImages = false
        errorMessage = nil
        generateImage()
    }
    
    private func generatePrompt() -> String {
        return """
# Task
Write a book for children under 5 years old.

# Requirements
- The total number of pages between 1 and \(pageCount).

# Characters in the Picture Book
1. Shiki-chan (older brother)
2. Shiro-chan (younger sister)
3. Mama (Shiki-chan and Shiro-chan's mother)

# Sample Answer
[
    {
        "IllustrationIdea":  "A picture of the older brother and younger sister looking at a pill bug in the park",
        "PageText": "ある日、お兄ちゃんと妹は公園に遊びに行ったところ、ダンゴムシを見つけました",
        "page": 1
    },
    {
        "IllustrationIdea":  "A picture of the pill bug curling up in surprise",
        "PageText": "ダンゴムシは突然丸くなったので、お兄ちゃんと妹はとてもびっくりしました",
        "page": 2
    }
]
"""
    }
    
    private func returnToMainMenu() {
        showingMainMenu = true
        bookPages = []
        currentPage = 0
        stopSpeech()
    }
    
    private func saveBook() {
        guard !bookPages.isEmpty else { return }
        
        // 保存容量チェック
        if savedBooks.count >= 10 {
            showingStorageAlert = true
            return
        }
        
        let title = "絵本 \(savedBooks.count + 1)"
        let savedBook = SavedBook(
            title: title,
            createdAt: Date(),
            pages: bookPages
        )
        
        savedBooks.append(savedBook)
        saveBooksToUserDefaults()
        
        // 保存完了のフィードバック
        errorMessage = "絵本を保存しました"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            errorMessage = nil
        }
    }
    
    private func loadBook(_ book: SavedBook) {
        bookPages = book.pages
        currentPage = 0
        showingMainMenu = false
        stopSpeech()
        // 絵本読み込み後に音声読み上げを開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startSpeech()
        }
    }
    
    private func deleteBook() {
        guard let bookToDelete = bookToDelete else { return }
        
        savedBooks.removeAll { $0.id == bookToDelete.id }
        saveBooksToUserDefaults()
        self.bookToDelete = nil
    }
    
    private func deleteOldestBook() {
        if let oldestBook = savedBooks.min(by: { $0.createdAt < $1.createdAt }) {
            savedBooks.removeAll { $0.id == oldestBook.id }
            saveBooksToUserDefaults()
        }
    }
    
    private func loadSavedBooks() {
        if let data = UserDefaults.standard.data(forKey: "SavedBooks"),
           let books = try? JSONDecoder().decode([SavedBook].self, from: data) {
            savedBooks = books
        }
    }
    
    private func saveBooksToUserDefaults() {
        if let data = try? JSONEncoder().encode(savedBooks) {
            UserDefaults.standard.set(data, forKey: "SavedBooks")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func nextPage() {
        if currentPage < bookPages.count - 1 {
            stopSpeech()
            currentPage += 1
            // 新しいページの音声読み上げを開始
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startSpeech()
            }
        }
    }
    
    private func previousPage() {
        if currentPage > 0 {
            stopSpeech()
            currentPage -= 1
            // 新しいページの音声読み上げを開始
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startSpeech()
            }
        }
    }
}

#Preview {
    ContentView()
}

