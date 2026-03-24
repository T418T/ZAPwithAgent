FROM node:lts-slim

# 必要なツールをインストール
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    python3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Claude Codeをインストール
RUN npm install -g @anthropic-ai/claude-code

# 非rootユーザーで動かす（セキュリティ向上）
RUN useradd -m -u 1001 claude
USER claude

# 作業ディレクトリ
WORKDIR /workspace

# CLAUDE.mdとスキルをコピー
COPY --chown=claude:claude CLAUDE.md ./CLAUDE.md
COPY --chown=claude:claude .claude/ ./.claude/

# レポート出力先
RUN mkdir -p /workspace/reports

# --dangerously-skip-permissions で無人実行
# TARGET_URL と診断開始の指示を渡して起動
ENTRYPOINT ["/bin/sh", "-c"]
CMD ["claude --dangerously-skip-permissions -p \"zap-scanスキルを使って${TARGET_URL}の脆弱性診断を実施してください\""]
