#!/bin/bash
# Smart Watchdog v3: проверяет WAL + gateway, чинит проблемы
# Безопасная версия: нет kill -9, порт из конфига, JSON5-совместимость

# Пути (configurable)
CONFIG="${OPENCLAW_CONFIG:-$HOME/.openclaw/openclaw.json}"
BACKUP="$HOME/.openclaw/openclaw.json.bak"
LOG="${OPENCLAW_LOG:-$HOME/.openclaw/watchdog.log}"
DB="${OPENCLAW_DB:-$HOME/.openclaw/memory/main.sqlite}"
MAX_RETRIES=3

# Порт из конфига (не hardcoded)
get_gateway_port() {
    # Пробуем jq (поддерживает комментарии если JSON5)
    if command -v jq &>/dev/null; then
        jq -r '.gateway.port // 18789' "$CONFIG" 2>/dev/null && return
    fi
    # Fallback на Python
    python3 -c "import json; print(json.load(open('$CONFIG')).get('gateway',{}).get('port',18789))" 2>/dev/null || echo "18789"
}

GATEWAY_PORT=$(get_gateway_port)
HEALTH_URL="http://127.0.0.1:${GATEWAY_PORT}/health"

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
if curl -sf "$HEALTH_URL" --connect-timeout 5 > /dev/null 2>&1; then
    exit 0  # Всё ок
fi

log "⚠️ Gateway не отвечает на порту $GATEWAY_PORT, начинаю диагностику"

# 2. Проверяем конфиг (jq более устойчив чем python json)
config_valid=false
if command -v jq &>/dev/null; then
    if jq empty "$CONFIG" 2>/dev/null; then
        config_valid=true
    fi
else
    if python3 -c "import json; json.load(open('$CONFIG'))" 2>/dev/null; then
        config_valid=true
    fi
fi

if [ "$config_valid" = false ]; then
    log "❌ Конфиг невалидный! Восстанавливаю из бэкапа"
    if [ -f "$BACKUP" ]; then
        cp "$BACKUP" "$CONFIG"
        log "✅ Конфиг восстановлен из бэкапа"
    else
        log "❌ Бэкап не найден!"
    fi
fi

# 3. Проверяем диск
if command -v df &>/dev/null; then
    DISK_USED=$(df -h / | tail -1 | awk '{gsub(/%/,""); print $5}')
    if [ "${DISK_USED:-0}" -gt 95 ]; then
        log "⚠️ Диск заполнен на ${DISK_USED}%! Показываю что можно почистить:"
        # НЕ удаляем автоматически - только логируем
        find /tmp -name "tts_*" -o -name "whisper_*" 2>/dev/null | head -20 >> "$LOG"
        log "Запустите очистку вручную если нужно"
    fi
fi

# 4. Проверяем порт (graceful stop, не kill -9)
if lsof -nP -iTCP:${GATEWAY_PORT} -sTCP:LISTEN > /dev/null 2>&1; then
    log "⚠️ Порт ${GATEWAY_PORT} занят, пробуем graceful stop"
    
    # Сначала пробуем через OpenClaw CLI
    if openclaw gateway stop 2>/dev/null; then
        sleep 3
        log "✅ Gateway остановлен через CLI"
    else
        # Graceful SIGTERM (не SIGKILL!)
        PID=$(lsof -nP -iTCP:${GATEWAY_PORT} -sTCP:LISTEN -t 2>/dev/null | head -1)
        if [ -n "$PID" ]; then
            log "Отправляем SIGTERM процессу $PID"
            kill "$PID" 2>/dev/null  # Graceful termination
            sleep 5
            
            # Проверяем что процесс завершился
            if kill -0 "$PID" 2>/dev/null; then
                log "⚠️ Процесс не завершился за 5 секунд, пробуем SIGKILL"
                kill -9 "$PID" 2>/dev/null
                sleep 2
            fi
        fi
    fi
fi

# 5. Handoff (если скрипт существует)
HANDOFF_SCRIPT="$HOME/.openclaw/agents/main/agent/scripts/pre-restart-handoff.sh"
if [ -x "$HANDOFF_SCRIPT" ]; then
    "$HANDOFF_SCRIPT" 2>/dev/null || true
fi

# 6. Пробуем запустить
for i in $(seq 1 $MAX_RETRIES); do
    log "Попытка запуска $i/$MAX_RETRIES"
    
    # Используем openclaw CLI
    if openclaw gateway start 2>/dev/null; then
        sleep 5
        if curl -sf "$HEALTH_URL" --connect-timeout 5 > /dev/null 2>&1; then
            log "✅ Gateway запущен с попытки $i"
            exit 0
        fi
    fi
    
    sleep 3
done

# 7. Алерт - НЕ читаем токен из конфига напрямую
log "❌ Gateway не запускается после $MAX_RETRIES попыток!"

# Если есть переменная окружения - используем её
if [ -n "$WATCHDOG_ALERT_CHAT" ] && [ -n "$TELEGRAM_BOT_TOKEN" ]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${WATCHDOG_ALERT_CHAT}" \
        -d "text=🚨 Gateway не запускается! Последний лог: $(tail -3 "$LOG")" > /dev/null 2>&1
    log "📨 Алерт отправлен"
else
    log "⚠️ WATCHDOG_ALERT_CHAT или TELEGRAM_BOT_TOKEN не заданы, алерт не отправлен"
fi

exit 1
