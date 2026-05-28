# 🧮 高度な電卓 (Advanced Calculator)

> 記号計算・微積分・統計に対応した、Android向け高機能電卓アプリ

[![Build Android APK](https://github.com/YOUR_USERNAME/advanced_calculator/actions/workflows/build.yml/badge.svg)](https://github.com/YOUR_USERNAME/advanced_calculator/actions/workflows/build.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.22.0-blue)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## ✨ 機能

| モード | 機能 |
|--------|------|
| **四則演算** | ＋ − × ÷、括弧、パーセント |
| **応用計算** | √、x²、xⁿ、絶対値、π |
| **場合の数** | 順列 nPr、組合せ nCr、階乗 n! |
| **解析学** | 記号微分 d/dx、数値積分 ∫（定積分・不定積分） |
| **関数** | sin/cos/tan、log₁₀、ln、exp、e |
| **数列** | Σ（シグマ和）、Π（総積）、一般項入力 |
| **統計** | 平均、中央値、最頻値、分散、標準偏差、四分位数 |

---

## 🏗️ 技術スタック

### フレームワーク: Flutter (Dart)
- **選定理由**: Dartの型安全性、高品質なUIレンダリング、GitHub ActionsでのAPKビルドの豊富な実績
- **最小サポートAndroid**: API 21 (Android 5.0)

### 数式処理エンジン: math.js (WebView経由)
- `flutter_inappwebview` で非表示WebViewを起動
- math.js v12 の `math.derivative()` による **記号微分**
- シンプソン法による **高精度数値積分**（10,000分割）
- math.js の `math.permutations()`, `math.combinations()`, `math.factorial()` による場合の数計算
- 統計: `math.mean()`, `math.variance()`, `math.std()`, `math.quantileSeq()` など

```
Flutter (Dart) UI
      ↕  JavaScript Bridge (flutter_inappwebview)
Hidden WebView
      ↕  math.js v12 CAS Engine
計算結果 → Flutter UI
```

---

## 📁 ディレクトリ構成

```
advanced_calculator/
├── .github/
│   └── workflows/
│       └── build.yml          # CI/CD: APKビルド & Artifacts保存
├── android/
│   └── app/
│       └── build.gradle       # Androidビルド設定
├── assets/
│   └── mathjs_engine.html     # math.js CASエンジン (WebView)
├── lib/
│   ├── main.dart              # アプリエントリーポイント & ホーム画面
│   ├── models/
│   │   └── calculator_state.dart   # 状態管理 (ChangeNotifier)
│   ├── services/
│   │   └── math_engine_service.dart # Flutter↔math.js ブリッジ
│   ├── theme/
│   │   └── app_theme.dart     # カラーパレット & フォント定義
│   ├── widgets/
│   │   ├── calc_button.dart   # 電卓ボタン (アニメーション付き)
│   │   ├── calc_display.dart  # 計算式・結果表示エリア
│   │   └── multi_input_field.dart # 複数入力フィールド
│   └── screens/
│       ├── basic_screen.dart          # 四則演算・応用・関数
│       ├── calculus_screen.dart       # 微分・積分
│       ├── combinatorics_screen.dart  # 場合の数
│       ├── sequences_screen.dart      # 数列 (Σ, Π)
│       ├── statistics_screen.dart     # 統計
│       └── history_screen.dart        # 計算履歴
└── pubspec.yaml               # 依存関係定義
```

---

## 🚀 セットアップ & ビルド手順

### 1. 前提条件のインストール

```bash
# Flutter SDK のインストール (公式サイト参照)
# https://docs.flutter.dev/get-started/install

# バージョン確認
flutter --version   # Flutter 3.22.0+
java -version       # Java 17+

# Android SDK が必要 (Android Studio 推奨)
flutter doctor      # 全チェックグリーンを確認
```

### 2. プロジェクトのセットアップ

```bash
# リポジトリをクローン
git clone https://github.com/YOUR_USERNAME/advanced_calculator.git
cd advanced_calculator

# 依存関係をインストール
flutter pub get

# 静的解析
flutter analyze

# テスト実行
flutter test
```

### 3. ローカルAPKビルド

```bash
# Debug APK (開発・テスト用)
flutter build apk --debug
# 出力: build/app/outputs/flutter-apk/app-debug.apk

# Release APK (配布用・ABI分割)
flutter build apk --release --split-per-abi
# 出力:
#   build/app/outputs/flutter-apk/app-arm64-v8a-release.apk   (64bit)
#   build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (32bit)
#   build/app/outputs/flutter-apk/app-x86_64-release.apk      (エミュレーター)

# 接続済みデバイスで直接実行
flutter run
```

### 4. デバイスへのインストール

```bash
# ADB でインストール
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## 🤖 GitHub Actions CI/CD

### トリガー
| イベント | 動作 |
|----------|------|
| `main` / `develop` へのpush | 自動ビルド + Artifacts保存 |
| Pull Request | ビルド + PR へコメント通知 |
| `v*.*.*` タグのpush | ビルド + GitHub Release 自動作成 |
| 手動実行 (`workflow_dispatch`) | debug/release 選択可能 |

### リリース手順

```bash
# タグを打つだけで自動的に GitHub Release が作成される
git tag v1.0.0
git push origin v1.0.0
```

### リリース署名設定（任意・本番配布時）

以下の Secrets をリポジトリの `Settings → Secrets and variables → Actions` に追加：

| Secret 名 | 内容 |
|-----------|------|
| `KEYSTORE_BASE64` | `base64 -w 0 your-keystore.jks` の出力 |
| `KEYSTORE_PASSWORD` | キーストアのパスワード |
| `KEY_ALIAS` | キーのエイリアス |
| `KEY_PASSWORD` | キーのパスワード |

```bash
# キーストアを Base64 に変換
base64 -w 0 your-keystore.jks
```

---

## 📦 主な依存パッケージ

```yaml
flutter_inappwebview: ^6.0.0    # WebView経由でmath.jsを実行
flutter_math_fork: ^0.7.2       # LaTeX数式レンダリング
math_expressions: ^2.4.0        # 基本算術フォールバック
google_fonts: ^6.2.1            # IBM Plex Mono / Space Grotesk フォント
flutter_animate: ^4.5.0         # UIアニメーション
provider: ^6.1.2                # 状態管理
```

---

## 📝 使用上の注意

- **微分の記号計算**: `math.js` の `math.derivative()` はポリノミアル・三角関数・指数対数関数など主要関数に対応。合成関数・積の微分も自動処理。
- **積分の数値計算**: シンプソン法（10,000分割）で高精度計算。解析的な不定積分はヒント表示のみ。
- **インターネット接続**: `math.js` は CDN から読み込みます。オフライン使用時は `assets/mathjs_engine.js` にローカルコピーを配置してください。

---

## 📄 ライセンス

MIT License — © 2025 Your Name
