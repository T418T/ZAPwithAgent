#!/bin/sh
# 変数が正しく設定されているかチェックする
set -eu

# TARGET_URLからホスト名を抽出
TARGET_HOST=$(echo "$TARGET_URL" | sed 's|https\?://||' | cut -d'/' -f1 | cut -d':' -f1)

# host.docker.internalはDNS解決が不安定なのでIPに変換する
if [ "$TARGET_HOST" = "host.docker.internal" ]; then
    TARGET_IP=$(getent hosts host.docker.internal | awk '{print $1}')
    if [ -z "$TARGET_IP" ]; then
        echo "[entrypoint] ERROR: host.docker.internal の名前解決に失敗しました" >&2
        exit 1
    fi
    echo "[entrypoint] host.docker.internal → $TARGET_IP に解決しました"
    TARGET_ACL_NAME="allowed_target_ip"
    TARGET_ACL_LINE="acl ${TARGET_ACL_NAME} dst ${TARGET_IP}"
else
    echo "[entrypoint] 診断対象ホスト: $TARGET_HOST"
    TARGET_ACL_NAME="allowed_target_domain"
    TARGET_ACL_LINE="acl ${TARGET_ACL_NAME} dstdomain ${TARGET_HOST}"
fi

cat > /etc/squid/squid.conf << EOF

# ────────────────────────────────────────
# おまじない
# ────────────────────────────────────────
max_filedescriptors 1024

# ────────────────────────────────────────
# 許可宛先の定義
# ────────────────────────────────────────

# Anthropic API（ドメイン指定）
acl allowed_api dstdomain api.anthropic.com

# 診断対象（TARGET_URLから動的生成）
${TARGET_ACL_LINE}

# アクセス元（docker内部ネットワーク全体を許可）
acl allowed_src src 172.16.0.0/12 10.0.0.0/8 192.168.0.0/16

# ────────────────────────────────────────
# アクセス制御
# ────────────────────────────────────────
http_access allow allowed_src allowed_api
http_access allow allowed_src ${TARGET_ACL_NAME}
http_access deny all

# ────────────────────────────────────────
# プロキシ設定
# ────────────────────────────────────────
http_port 3128

# ログ
access_log daemon:/var/log/squid/access.log
cache_log /var/log/squid/cache.log
EOF

echo "[entrypoint] squid.conf を生成しました"
echo "[entrypoint] 許可宛先: api.anthropic.com + $TARGET_HOST"

exec squid -f /etc/squid/squid.conf -NYCd 1
