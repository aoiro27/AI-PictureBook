//
//  ContentView.swift
//  AIPictureBook
//
//  Created by Yuki Usui on 2025/07/17.
//

import SwiftUI

struct ContentView: View {
    @State private var prompt: String = ""
    @State private var imageUrl: String? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI画像生成")
                .font(.title)
                .padding(.top)
            TextField("プロンプトを入力", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            Button(action: generateImage) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("生成")
                }
            }
            .disabled(prompt.isEmpty || isLoading)
            .padding()
            if let url = imageUrl, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300, maxHeight: 300)
                    case .failure:
                        Image(systemName: "xmark.octagon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            Spacer()
        }
    }
    
    func generateImage() {
        guard let url = URL(string: "https://ai-picture-488889291017.asia-northeast1.run.app") else { return }
        isLoading = true
        errorMessage = nil
        imageUrl = nil
        let body: [String: Any] = ["prompt": prompt]
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "通信エラー: \(error.localizedDescription)"
                    return
                }
                guard let data = data else {
                    errorMessage = "データがありません"
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let url = json["image_url"] as? String {
                        imageUrl = url
                    } else {
                        errorMessage = "画像URLが取得できませんでした"
                    }
                } catch {
                    errorMessage = "JSON解析エラー: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

#Preview {
    ContentView()
}
