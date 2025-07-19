//
//  ContentView.swift
//  AIPictureBook
//
//  Created by Yuki Usui on 2025/07/17.
//

import SwiftUI

struct ContentView: View {
    @State private var bookPages: [BookPage] = []
    @State private var currentPage: Int = 0
    @State private var isLoading: Bool = false
    @State private var showingMainMenu: Bool = true
    @State private var showingDeleteAlert: Bool = false
    @State private var showingStorageAlert: Bool = false
    @State private var bookToDelete: SavedBook? = nil
    @State private var pageCount: Int = 3
    @State private var showingPageCountInput: Bool = false
    @State private var showingPromptInput: Bool = false
    @State private var customPrompt: String = ""
    
    @StateObject private var speechManager = SpeechManager()
    @StateObject private var bgmManager = BGMManager()
    @StateObject private var bookGenerationService = BookGenerationService()
    @StateObject private var storageManager = BookStorageManager()
    
    var body: some View {
        ZStack {
            // 背景画像
            Image("bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
            
            
            VStack(spacing: 20) {
                
                if showingMainMenu {
                    // メインメニュー
                    mainMenuView
                            } else if showingPageCountInput {
                // ページ数入力画面
                pageCountInputView
            } else if showingPromptInput {
                // プロンプト入力画面
                promptInputView
                            } else if bookPages.isEmpty || bookGenerationService.isGeneratingImages {
                    // 初期画面または画像生成中
                    VStack(spacing: 30) {
                        if bookGenerationService.isGeneratingImages {
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
                    VStack(spacing: 10) {
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
                            
                            HStack(spacing: 10) {
                                Button(action: toggleBGM) {
                                    Image(systemName: bgmManager.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(15)
                                
                                Button(action: saveBook) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "square.and.arrow.down")
                                            .font(.title2)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(20)
                                }
                            }
                        //    .padding(.trailing)
                        }
                        .padding(.top, 50)
                        .padding(.horizontal, 70)
                        
                                            // 絵本ページ
                    VStack(spacing: 15) {
                        // 画像表示
                        if let imageUrl = bookPages[currentPage].imageUrl,
                           let imageURL = URL(string: imageUrl) {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .frame(height: UIScreen.main.bounds.height * 0.5)
                                case .success(let image):
                                     image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .frame(height: UIScreen.main.bounds.height * 0.5)
                                        .cornerRadius(15)
                                case .failure:
                                    Image(systemName: "photo")
                                        .font(.system(size: 100))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .frame(height: UIScreen.main.bounds.height * 0.5)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .frame(height: UIScreen.main.bounds.height * 0.5)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                )
                        }
                        
                        // テキスト表示
                        Text(bookPages[currentPage].text)
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 50)
                            .frame(minHeight: 60)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                        
                        // ページ送りボタン
                        HStack(spacing: 40) {
                            Button(action: previousPage) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(currentPage > 0 ? .blue : .gray)
                            }
                            .disabled(currentPage <= 0)
                            
                            Button(action: nextPage) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(currentPage < bookPages.count - 1 ? .blue : .gray)
                            }
                            .disabled(currentPage >= bookPages.count - 1)
                        }
                        .padding(.bottom)
                    }
                }
                
                if let error = bookGenerationService.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
        }
        .onAppear {
            // アプリ起動時にオープニングBGMを開始
            if !bgmManager.isOpeningPlaying {
                bgmManager.playOpeningBGM()
            }
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
        VStack(spacing: 15) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)
            
            Text("Your Picture Book")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack(spacing: 15) {
                    Button(action: {
                        showingMainMenu = false
                        showingPageCountInput = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("新しい絵本を作る")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                    }
                    
                    Button(action: toggleOpeningBGM) {
                        Image(systemName: bgmManager.isOpeningPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(25)
                    }
                }
                
                if !storageManager.savedBooks.isEmpty {
                    Text("保存済みの絵本")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(storageManager.savedBooks) { book in
                                savedBookRow(book)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    .frame(maxHeight: 250)
                    .padding(.bottom, 10)
                    .padding(.horizontal, 60)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 25))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("保存済みの絵本はありません")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("絵本を作成して保存してみましょう")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    private func savedBookRow(_ book: SavedBook) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.black)
                
                Text("\(book.pageCount)ページ • \(storageManager.formatDate(book.createdAt))")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // デバッグ情報
                Text("ID: \(book.id.uuidString.prefix(8))")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
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
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.95))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
                
                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        Button(action: { 
                            showingPageCountInput = false
                            showingMainMenu = true
                        }) {
                            Text("キャンセル")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(width: 120, height: 50)
                                .background(Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                        }
                        
                        Button(action: { 
                            showingPageCountInput = false
                            showingPromptInput = true
                        }) {
                            Text("次へ")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(width: 120, height: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                        }
                    }
                    
                    Button(action: toggleOpeningBGM) {
                        HStack(spacing: 8) {
                            Image(systemName: bgmManager.isOpeningPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.title2)
                            Text(bgmManager.isOpeningPlaying ? "音楽停止" : "音楽再生")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    }
                }
            }
        }
        .padding()
    }
    
    private var promptInputView: some View {
        VStack(spacing: 30) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 80))
                .foregroundColor(.white)
            
            Text("絵本のテーマを入力")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 20) {
                Text("どんな絵本を作りたいですか？")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("例：「お友達と遊ぶ話」「動物の冒険」「家族の絆」など")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("テーマ（任意）")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $customPrompt)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                }
                
                Text("空欄の場合は、デフォルトのテーマで絵本を作成します")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        Button(action: { 
                            showingPromptInput = false
                            showingPageCountInput = true
                        }) {
                            Text("戻る")
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
                    
                    Button(action: toggleOpeningBGM) {
                        HStack(spacing: 8) {
                            Image(systemName: bgmManager.isOpeningPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.title2)
                            Text(bgmManager.isOpeningPlaying ? "音楽停止" : "音楽再生")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    }
                }
            }
        }
        .padding()
    }
    
    func generateImage() {
        isLoading = true
        
        bookGenerationService.generateBook(pageCount: pageCount, customPrompt: customPrompt) { pages in
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let pages = pages {
                    self.bookPages = pages
                    self.currentPage = 0
                    
                    // オープニングBGMを停止して絵本BGMを開始
                    self.bgmManager.stopOpeningBGM()
                    self.bgmManager.playBGM()
                    
                    // 画像URL更新のコールバックを設定
                    self.bookGenerationService.onImageGenerated = { pageIndex, imageUrl in
                        DispatchQueue.main.async {
                            if pageIndex < self.bookPages.count {
                                self.bookPages[pageIndex].imageUrl = imageUrl
                                self.bookPages[pageIndex].imageLoadingStatus = .success
                            }
                        }
                    }
                    
                    // 画像生成を開始
                    self.bookGenerationService.generateImagesSequentially(pages: pages) {
                        // 画像生成完了後に音声読み上げを開始
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.startSpeech()
                        }
                    }
                }
            }
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
    
    private func toggleBGM() {
        if bgmManager.isPlaying {
            bgmManager.pauseBGM()
        } else {
            bgmManager.resumeBGM()
        }
    }
    
    private func toggleOpeningBGM() {
        if bgmManager.isOpeningPlaying {
            bgmManager.pauseOpeningBGM()
        } else {
            bgmManager.resumeOpeningBGM()
        }
    }
    
    // MARK: - 保存・読み込み・削除機能
    
    private func createNewBook() {
        showingPageCountInput = true
    }
    
    private func startBookGeneration() {
        showingPageCountInput = false
        showingPromptInput = false
        showingMainMenu = false
        bookPages = []
        currentPage = 0
        isLoading = false
        generateImage()
    }
    

    
    private func returnToMainMenu() {
        showingMainMenu = true
        showingPageCountInput = false
        showingPromptInput = false
        customPrompt = ""
        bookPages = []
        currentPage = 0
        stopSpeech()
        bgmManager.stopBGM()
        // メインメニューに戻ったらオープニングBGMを再開
        if !bgmManager.isOpeningPlaying {
            bgmManager.playOpeningBGM()
        }
    }
    
    private func saveBook() {
        guard !bookPages.isEmpty else { return }
        
        if storageManager.saveBook(bookPages) {
            // 保存完了のフィードバック
            bookGenerationService.errorMessage = "絵本を保存しました"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.bookGenerationService.errorMessage = nil
            }
        } else {
            showingStorageAlert = true
        }
    }
    
    private func loadBook(_ book: SavedBook) {
        bookPages = storageManager.loadBook(book)
        currentPage = 0
        showingMainMenu = false
        showingPageCountInput = false
        stopSpeech()
        // オープニングBGMを停止して絵本BGMを開始
        bgmManager.stopOpeningBGM()
        bgmManager.playBGM()
        // 絵本読み込み後に音声読み上げを開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startSpeech()
        }
    }
    
    private func deleteBook() {
        guard let bookToDelete = bookToDelete else { return }
        
        storageManager.deleteBook(bookToDelete)
        self.bookToDelete = nil
    }
    
    private func deleteOldestBook() {
        storageManager.deleteOldestBook()
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

