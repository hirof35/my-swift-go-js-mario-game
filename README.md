# Go & Swift & HTML5 2D Platformer Game

Go言語のバックエンドサーバーからステージデータを取得し、iOS（Swift）およびブラウザ（HTML5/JS）の両方で遊ぶことができる、クロスプラットフォームの2Dアクションゲームです。
<img width="1302" height="1107" alt="スクリーンショット 2026-05-20 072229" src="https://github.com/user-attachments/assets/9645e634-aa0d-4661-8f77-6dc8bda7f4f0" />
## 🎮 機能特徴
- **マルチフロントエンド**: 同一のGo APIからステージデータを取得し、Swift（SpriteKit）とHTML5（Canvas）の双方で同一のステージを再現。
- **4つのシーン構造**: タイトル ＞ ゲームメイン ＞ ゲームオーバー / ステージクリア の状態管理。
- **敵キャラクターAI**: 4パターンの異なるアルゴリズム（前進、往復、ジャンプ、ボス）。
- **ボス怒りモード**: ボスの残りHPが1になると、移動速度が2倍になり、ジャンプ頻度が向上するフェーズ移行システム。

## 🛠️ 起動方法

### 1. バックエンド（Go）の起動
```bash
cd backend
go run main.go
http://localhost:8080 でAPIサーバーが起動します。

2. ブラウザ版（HTML5/JS）の起動
frontend-web/index.html をブラウザ（ChromeやSafariなど）で直接開いてください。

← → キー：移動

スペース キー：ジャンプ

3. iOS版（Swift）の起動
frontend-ios/GameScene.swift のコードをXcodeのSpriteKitプロジェクトに組み込み、シミュレータまたは実機で起動してください。

画面タップ：ジャンプ

