package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

// ブロックの構造体
type Block struct {
	Type string  `json:"type"` // "ground" (床), "brick" (レンガ)
	X    float64 `json:"x"`
	Y    float64 `json:"y"`
}

// 敵キャラクターの構造体
type Enemy struct {
	Type string  `json:"type"` // "goomba" (前進), "turtle" (往復), "jumper" (跳ねる), "boss" (ボス)
	X    float64 `json:"x"`
	Y    float64 `json:"y"`
}

// ステージ全体の構造体
type StageData struct {
	StageID int     `json:"stage_id"`
	Blocks  []Block `json:"blocks"`
	Enemies []Enemy `json:"enemies"`
}

// スコア保存用の構造体
type ClearRequest struct {
	PlayerName string `json:"player_name"`
	Score      int    `json:"score"`
}

// CORS（ブラウザ通信制限）を解除する共通関数
func setupCORS(w *http.ResponseWriter, r *http.Request) bool {
	(*w).Header().Set("Access-Control-Allow-Origin", "*")
	(*w).Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
	(*w).Header().Set("Access-Control-Allow-Headers", "Content-Type")
	
	// プレフライトリクエスト（OPTIONS）への対応
	if r.Method == "OPTIONS" {
		(*w).WriteHeader(http.StatusOK)
		return true
	}
	return false
}

// ステージデータ配信API
func stageHandler(w http.ResponseWriter, r *http.Request) {
	if setupCORS(&w, r) { return }
	w.Header().Set("Content-Type", "application/json")

	stage := StageData{
		StageID: 1,
		Blocks: []Block{
			{Type: "ground", X: 150, Y: 20},
			{Type: "ground", X: 450, Y: 20},
			{Type: "brick", X: 260, Y: 120},
			{Type: "brick", X: 300, Y: 120},
			{Type: "brick", X: 340, Y: 120},
		},
		Enemies: []Enemy{
			{Type: "goomba", X: 200, Y: 60},  // ただ左に進む
			{Type: "turtle", X: 400, Y: 60},  // 左右に往復する
			{Type: "jumper", X: 550, Y: 60},  // 定期的に跳ねる
			{Type: "boss",   X: 750, Y: 100}, // 巨大ボス（HP3 / 怒りあり）
		},
	}

	json.NewEncoder(w).Encode(stage)
}

// スコア保存API
func clearHandler(w http.ResponseWriter, r *http.Request) {
	if setupCORS(&w, r) { return }
	
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req ClearRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// コンソールに出力（実務ではここでDB保存）
	fmt.Printf("🏆【ステージクリア通知】 プレイヤー: %s, スコア: %d\n", req.PlayerName, req.Score)

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"success"}`))
}

func main() {
	http.HandleFunc("/api/stage", stageHandler)
	http.HandleFunc("/api/clear", clearHandler)

	fmt.Println("🚀 Go Game Server started on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}