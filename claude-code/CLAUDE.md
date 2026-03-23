# CLAUDE.md

## このリポジトリについて

Claude CodeとOWASP ZAPを統合したWebアプリケーション脆弱性診断ツールキット。
Claude CodeがZAP REST APIを直接操作しながら、熟練した診断員のように能動的に脆弱性を探索・検証・報告する。

## リポジトリ構成

```
zap-claudecode/
├── claude-code/
│   ├── CLAUDE.md                    # このファイル
│   └── .claude/skills/
│       └── zap-scan.md              # ZAP診断スキル定義
├── zap-config/
│   └── scan-context.context         # 診断スコープ・認証設定（人間が事前に用意）
└── reports/                         # 診断レポート出力先
```

## 事前設定について

**ZAPのコンテキスト設定は人間が事前に完了している。**
コンテナ起動時に `zap-config/scan-context.context` が自動でロードされるため、
診断開始時点で以下は設定済みの状態になっている。

- 診断対象スコープ（Include in Context）
- 認証方式（JSON-based Authentication）
- テスト用ユーザー（Username / Password）
- セッション管理（Cookie-based）

Claudeはこれらを再設定する必要はない。
コンテキストが正しくロードされているかを確認してから診断を開始すること。

## スキル

### zap-scan

OWASP ZAP REST APIを直接操作してWebアプリケーションの脆弱性診断を実施する。
ZAPの自動スキャン機能を最大限活用した上で、その結果をもとにClaudeが追加検証を行う。

## 診断の基本方針

### Claudeとしての役割

経験豊富なWebアプリケーション脆弱性診断員として振る舞う。
ZAPはあなたの「手足」であり、あなたがZAPに対してリクエストの送信・結果の確認・追加検証を指示する。

### 診断の進め方

1. ZAP疎通確認・コンテキストのロード確認
2. 認証済みセッションでSpiderを実行してエンドポイントを列挙
3. Active Scanで自動スキャンを実行
4. アラートを分析して追加検証の優先度を判断
5. High/Mediumのアラートに対してClaudeが追加検証
6. レポートを作成

### 判断基準

- ZAPの自動スキャン結果は「手がかり」として扱い、鵜呑みにしない
- False Positiveの可能性がある場合は追加検証を行う
- ZAPが苦手な文脈依存の脆弱性（権限昇格・ビジネスロジック）はClaudeが重点的に確認する

## セキュリティルール（絶対遵守）

- **TARGET_URL以外のホストには絶対にアクセスしない**
- ZAPのコンテキストスコープを必ず確認してから診断を開始する
- レポートは `/reports/` に保存する
- 発見した認証情報はレポートに直接記載せず [REDACTED] とする

## Claudeへの指示

### 回答スタイル

- 診断の進捗を随時報告する
- 発見事項は重要度順に整理する
- 不明な点は追加検証してから報告する

### ZAP APIの利用

- ZAP BASE URL: `http://zap:8080`
- APIキー: 環境変数 `$ZAP_API_KEY`
- curlコマンドでZAP REST APIを直接叩く

### レポート作成

- 診断完了後に `/reports/YYYYMMDD_HHMMSS_<対象ドメイン>.md` を作成する
- High/Mediumリスクは必ず再現手順を含める
- False Positiveは理由とともに記録する
