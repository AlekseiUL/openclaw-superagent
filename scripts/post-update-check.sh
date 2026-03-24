#!/bin/bash
# Post-update check: полная проверка системы после обновления OpenClaw
# Работает на macOS и Linux

WORKSPACE="$HOME/.openclaw/workspace"
RESULT=""

echo "🔍 Post-update check started at $(date)"

# 1. Gateway
echo "=== Gateway ==="
STATUS=$(openclaw status 2>&1)
if echo "$STATUS" | grep -q "running"; then
    echo "✅ Gateway running"
else
    echo "❌ Gateway NOT running!"
    RESULT="$RESULT\n❌ Gateway не работает"
    openclaw gateway start 2>/dev/null
fi

# 2. WAL mode
echo "=== WAL Mode ==="
WAL=$(sqlite3 ~/.openclaw/memory/main.sqlite "PRAGMA journal_mode" 2>&1)
if [ "$WAL" = "wal" ]; then
    echo "✅ WAL mode OK"
else
    sqlite3 ~/.openclaw/memory/main.sqlite "PRAGMA journal_mode=wal;" 2>/dev/null
    RESULT="$RESULT\n⚠️ WAL mode починен"
fi

# 3. Критичные файлы
echo "=== Critical Files ==="
for f in SOUL.md IDENTITY.md AGENTS.md MEMORY.md USER.md TOOLS.md HEARTBEAT.md; do
    if [ -f "$WORKSPACE/$f" ]; then
        echo "✅ $f"
    else
        echo "❌ $f MISSING!"
        RESULT="$RESULT\n❌ $f отсутствует!"
    fi
done

# 4. Права (кроссплатформенно)
echo "=== Permissions ==="
if [ "$(uname)" = "Darwin" ]; then
    PERM=$(stat -f "%Lp" ~/.openclaw/openclaw.json 2>/dev/null)
else
    PERM=$(stat -c "%a" ~/.openclaw/openclaw.json 2>/dev/null)
fi
if [ "$PERM" = "600" ]; then
    echo "✅ Permissions OK"
else
    chmod 600 ~/.openclaw/openclaw.json
    RESULT="$RESULT\n⚠️ Права исправлены"
fi

# 5. Gateway bind
echo "=== Gateway Bind ==="
BIND=$(python3 -c "import json; print(json.load(open('$HOME/.openclaw/openclaw.json')).get('gateway',{}).get('bind','unknown'))" 2>/dev/null)
if [ "$BIND" = "loopback" ] || [ "$BIND" = "127.0.0.1" ]; then
    echo "✅ Gateway bind: $BIND"
else
    echo "❌ Gateway bind: $BIND (UNSAFE!)"
    RESULT="$RESULT\n❌ Gateway bind: $BIND"
fi

# 6. Watchdog
echo "=== Watchdog ==="
if [ "$(uname)" = "Darwin" ]; then
    launchctl list 2>/dev/null | grep -q "watchdog" && echo "✅ Watchdog active" || echo "⚠️ Watchdog missing"
else
    systemctl --user is-active openclaw-watchdog.timer > /dev/null 2>&1 && echo "✅ Watchdog active" || echo "⚠️ Watchdog missing"
fi

# Итог
echo ""
if [ -z "$RESULT" ]; then
    echo "✅ Обновление прошло чисто"
else
    echo "⚠️ Найдены проблемы:"
    echo -e "$RESULT"
fi
