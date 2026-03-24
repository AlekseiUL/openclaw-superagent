#!/bin/bash
# Smart Watchdog v2: проверяет WAL + gateway, чинит проблемы
HEALTH_URL="http://127.0.0.1:18789/health"
CONFIG="$HOME/.openclaw/openclaw.json"
BACKUP="$HOME/.openclaw/openclaw.json.bak"
LOG="$HOME/.openclaw/watchdog.log"
DB="$HOME/.openclaw/memory/main.sqlite"
MAX_RETRIES=3

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"; }

# 0. Гарантируем WAL mode (каждый цикл)
if [ -f "$DB" ]; then
    MODE=$(sqlite3 "$DB" "PRAGMA journal_mode;" 2>/dev/null)
    if [ "$MODE" != "wal" ]; then
        sqlite3 "$DB" "PRAGMA journal_mode=wal;" 2>/dev/null
        log "WAL restored (was: $MODE)"
    fi
fi

# 1. Проверяем здоровье gateway
if curl -sf "$HEALTH_URL" > /dev/null 2>&1; then
    exit 0  # Всё ок
fi

log "⚠️ Gateway не отвечает, начинаю диагностику"

# 2. Проверяем конфиг
if ! python3 -c "import json; json.load(open('$CONFIG'))" 2>/dev/null; then
    log "❌ Конфиг невалидный JSON! Восстанавливаю из бэкапа"
    if [ -f "$BACKUP" ]; then
        cp "$BACKUP" "$CONFIG"
        log "✅ Конфиг восстановлен из бэкапа"
    else
        log "❌ Бэкап не найден!"
    fi
fi

# 3. Проверяем диск
DISK_USED=$(df -h / | tail -1 | awk '{gsub(/%/,""); print $5}')
if [ "$DISK_USED" -gt 95 ]; then
    log "❌ Диск заполнен на ${DISK_USED}%! Чищу tmp"
    find /tmp -name "tts_*" -o -name "whisper_*" -delete 2>/dev/null
    find "$HOME/.openclaw/agents/main/sessions/" -name "*.jsonl" -mtime +7 -delete 2>/dev/null
fi

# 4. Проверяем порт
if lsof -nP -iTCP:18789 -sTCP:LISTEN > /dev/null 2>&1; then
    log "⚠️ Порт 18789 занят, убиваю"
    lsof -nP -iTCP:18789 -sTCP:LISTEN -t | xargs kill -9 2>/dev/null
    sleep 2
fi

# 5. Handoff
"$HOME/.openclaw/workspace/scripts/pre-restart-handoff.sh" 2>/dev/null

# 6. Пробуем запустить
for i in $(seq 1 $MAX_RETRIES); do
    log "Попытка запуска $i/$MAX_RETRIES"
    openclaw gateway start 2>/dev/null
    sleep 5
    if curl -sf "$HEALTH_URL" > /dev/null 2>&1; then
        log "✅ Gateway запущен с попытки $i"
        exit 0
    fi
done

# 7. Алерт в Telegram
log "❌ Gateway не запускается после $MAX_RETRIES попыток!"
BOT_TOKEN=$(python3 -c "import json; print(json.load(open('$CONFIG'))['channels']['telegram']['botToken'])" 2>/dev/null)
if [ -n "$BOT_TOKEN" ]; then
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=[OWNER_ID]" \
        -d "text=🚨 Gateway не запускается! Последний лог: $(tail -3 $LOG)" > /dev/null 2>&1
    log "📨 Алерт отправлен"
fi
