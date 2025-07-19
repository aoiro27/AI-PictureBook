//
//  BookGenerationService.swift
//  AIPictureBook
//
//  Created by Yuki Usui on 2025/07/17.
//

import Foundation

class BookGenerationService: ObservableObject {
    @Published var isGeneratingImages: Bool = false
    @Published var errorMessage: String? = nil
    
    private let bookGenerationURL = "https://ai-plot-488889291017.asia-northeast1.run.app"
    private let imageGenerationURL = "https://ai-picture-488889291017.asia-northeast1.run.app"
    
    func generateBook(pageCount: Int, customPrompt: String, completion: @escaping ([BookPage]?) -> Void) {
        let prompt = generatePrompt(pageCount: pageCount, customPrompt: customPrompt)
        
        guard let url = URL(string: bookGenerationURL) else {
            errorMessage = "無効なURLです"
            completion(nil)
            return
        }
        
        let body: [String: Any] = ["prompt": prompt]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "絵本生成エラー: \(error.localizedDescription)"
                    completion(nil)
                    return
                }
                
                if let responseString = String(data: data!, encoding: .utf8) {
                    print("絵本生成レスポンス:", responseString)
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data!) as? [String: Any],
                           let answer = json["answer"] as? String {
                            
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
                                    
                                    tempPages.sort { $0.pageNumber < $1.pageNumber }
                                    completion(tempPages)
                                    return
                                }
                            }
                        }
                        
                        self.errorMessage = "絵本の内容を解析できませんでした"
                        completion(nil)
                    } catch {
                        self.errorMessage = "JSON解析エラー: \(error.localizedDescription)"
                        completion(nil)
                    }
                } else {
                    self.errorMessage = "レスポンスのデコードに失敗しました"
                    completion(nil)
                }
            }
        }.resume()
    }
    
    func generateImagesSequentially(pages: [BookPage], completion: @escaping () -> Void) {
        isGeneratingImages = true
        let constPrefix = "Shiki is a five-year-old human boy, and Shiro is his one-year-old little sister."
        generateImageSequentially(pages: pages, constPrefix: constPrefix, currentIndex: 0, completion: completion)
    }
    
    // 画像URLを更新するためのコールバック
    var onImageGenerated: ((Int, String) -> Void)?
    
    private func generateImageSequentially(pages: [BookPage], constPrefix: String, currentIndex: Int, completion: @escaping () -> Void) {
        guard currentIndex < pages.count else {
            isGeneratingImages = false
            completion()
            return
        }
        
        let page = pages[currentIndex]
        let prompt = constPrefix + page.illustrationIdea
        let pageIndex = currentIndex
        
        generateImage(prompt: prompt, pageIndex: pageIndex, retryCount: 0) { success in
            // 次のページの処理を10秒後に実行
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.generateImageSequentially(pages: pages, constPrefix: constPrefix, currentIndex: currentIndex + 1, completion: completion)
            }
        }
    }
    
    private func generateImage(prompt: String, pageIndex: Int, retryCount: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: imageGenerationURL) else {
            completion(false)
            return
        }
        
        let body: [String: Any] = ["prompt": prompt]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.handleImageRequestError(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount, error: error, completion: completion)
                    return
                }
                
                // HTTPステータスコードをチェック
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 500 && retryCount < 10 {
                        // 500エラーの場合、30秒待ってから再試行
                        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                            self.generateImage(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount + 1, completion: completion)
                        }
                        return
                    }
                }
                
                if let responseString = String(data: data!, encoding: .utf8) {
                    print("画像生成レスポンス: \(responseString)")
                }
                
                guard let data = data else {
                    self.handleImageRequestError(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount, error: nil, completion: completion)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let url = json["image_url"] as? String {
                        // 画像URLを更新
                        self.onImageGenerated?(pageIndex, url)
                        completion(true)
                    } else {
                        self.handleImageRequestError(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount, error: nil, completion: completion)
                    }
                } catch {
                    self.handleImageRequestError(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount, error: error, completion: completion)
                }
            }
        }.resume()
    }
    
    private func handleImageRequestError(prompt: String, pageIndex: Int, retryCount: Int, error: Error?, completion: @escaping (Bool) -> Void) {
        if retryCount < 3 {
            // 30秒待ってから再試行
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                self.generateImage(prompt: prompt, pageIndex: pageIndex, retryCount: retryCount + 1, completion: completion)
            }
        } else {
            // 3回試行しても失敗した場合
            self.errorMessage = "画像生成に失敗しました (ページ\(pageIndex + 1))"
            completion(false)
        }
    }
    
    private func generatePrompt(pageCount: Int, customPrompt: String) -> String {
        let themePrompt = customPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let themeSection = themePrompt.isEmpty ? "" : """
# Theme
\(themePrompt)

"""
        
        return """
# Task
Write a book for children under 5 years old.
theme is \(themeSection)

# Requirements
- The total number of pages is \(pageCount).
# Characters in the Picture Book
1. Shiki-chan (older brother)
2. Shiro-chan (younger sister)
3. Mama (Shiki-chan and Shiro-chan's mother)
- For your response, as in the sample, please return IllustrationIdea in English and PageText in Japanese.

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
} 