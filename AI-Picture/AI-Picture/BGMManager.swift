//
//  BGMManager.swift
//  AIPictureBook
//
//  Created by Yuki Usui on 2025/07/17.
//

import Foundation
import AVFoundation

class BGMManager: NSObject, ObservableObject {
    private var bookAudioPlayer: AVAudioPlayer?
    private var openingAudioPlayer: AVAudioPlayer?
    @Published var isPlaying: Bool = false
    @Published var isOpeningPlaying: Bool = false
    
    func playBGM() {
        guard let url = Bundle.main.url(forResource: "book", withExtension: "mp3") else {
            print("BGMファイルが見つかりません")
            return
        }
        
        do {
            bookAudioPlayer = try AVAudioPlayer(contentsOf: url)
            bookAudioPlayer?.numberOfLoops = -1 // 無限ループ
            bookAudioPlayer?.volume = 0.3 // 音量を30%に設定
            bookAudioPlayer?.play()
            isPlaying = true
        } catch {
            print("BGM再生エラー: \(error)")
        }
    }
    
    func playOpeningBGM() {
        guard let url = Bundle.main.url(forResource: "opening", withExtension: "mp3") else {
            print("オープニングBGMファイルが見つかりません")
            return
        }
        
        do {
            openingAudioPlayer = try AVAudioPlayer(contentsOf: url)
            openingAudioPlayer?.numberOfLoops = -1 // 無限ループ
            openingAudioPlayer?.volume = 0.4 // 音量を40%に設定
            openingAudioPlayer?.play()
            isOpeningPlaying = true
        } catch {
            print("オープニングBGM再生エラー: \(error)")
        }
    }
    
    func stopBGM() {
        bookAudioPlayer?.stop()
        isPlaying = false
    }
    
    func stopOpeningBGM() {
        openingAudioPlayer?.stop()
        isOpeningPlaying = false
    }
    
    func pauseBGM() {
        bookAudioPlayer?.pause()
        isPlaying = false
    }
    
    func pauseOpeningBGM() {
        openingAudioPlayer?.pause()
        isOpeningPlaying = false
    }
    
    func resumeBGM() {
        bookAudioPlayer?.play()
        isPlaying = true
    }
    
    func resumeOpeningBGM() {
        openingAudioPlayer?.play()
        isOpeningPlaying = true
    }
    
    func stopAllBGM() {
        stopBGM()
        stopOpeningBGM()
    }
} 