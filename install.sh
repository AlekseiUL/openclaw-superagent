#!/bin/bash
# Thoth System Installer — устанавливает полную систему агента в существующий OpenClaw
# Работает на macOS и Linux
# v2: additive mode - не перезаписывает существующие файлы без спроса

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🏗️  Thoth System Installer v2"
echo "  Полная система AI-агента для OpenClaw"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Режим установки
FORCE_OVERWRITE=false
for arg in "$@"; do
    case "$arg" in
        --force|-f) FORCE_OVERWRITE=true ;;
        --help|-h)
            echo "Usage: $0 [--force|-f] [--help|-h]"
            echo ""
            echo "  --force, -f   Перезаписать существующие файлы без спроса"
            echo "  --help, -h    Показать эту справку"
            echo ""
            echo "По умолчанию installer работает в additive режиме:"
            echo "- Существующие файлы НЕ перезаписываются"
            echo "- Новые файлы добавляются"
            echo "- Перед изменением создаётся backup"
            exit 0
            ;;
    esac
done

# Определяем workspace
OPENCLAW_DIR="$HOME/.openclaw"
if [ ! -d "$OPENCLAW_DIR" ]; then
    echo "❌ OpenClaw не найден ($OPENCLAW_DIR)"
    echo "Установите OpenClaw сначала: npm install -g openclaw && openclaw onboard"
    exit 1
fi

# Ищем workspace (используем jq если есть, иначе python)
if command -v jq &>/dev/null; then
    WORKSPACE=$(jq -r '.agents.defaults.workspace // empty' "$HOME/.openclaw/openclaw.json" 2>/dev/null)
fi
if [ -z "$WORKSPACE" ]; then
    WORKSPACE=$(python3 -c "
import json, os
try:
    d = json.load(open(os.path.expanduser('~/.openclaw/openclaw.json')))
    ws = d.get('agents',{}).get('defaults',{}).get('workspace','')
    print(ws if ws else '')
except:
    print('')
" 2>/dev/null)
fi
if [ -z "$WORKSPACE" ] || [ ! -d "$WORKSPACE" ]; then
    # Fallback на стандартный путь
    WORKSPACE="$HOME/.openclaw/agents/main/agent"
    if [ ! -d "$WORKSPACE" ]; then
        WORKSPACE="$HOME/.openclaw/workspace"
    fi
fi

echo "📂 Workspace: $WORKSPACE"

# Проверяем существующие файлы
EXISTING_FILES=0
for f in SOUL.md IDENTITY.md USER.md AGENTS.md MEMORY.md TOOLS.md HEARTBEAT.md BOOTSTRAP.md; do
    [ -f "$WORKSPACE/$f" ] && EXISTING_FILES=$((EXISTING_FILES + 1))
done

if [ $EXISTING_FILES -gt 0 ]; then
    echo ""
    echo "⚠️  Найдено $EXISTING_FILES существующих файлов в workspace"
    if [ "$FORCE_OVERWRITE" = false ]; then
        echo ""
        echo "Выберите режим установки:"
        echo "  1) Additive (рекомендуется) - добавить только новые файлы, существующие не трогать"
        echo "  2) Merge - показать diff для каждого файла, выбрать что оставить"
        echo "  3) Overwrite - перезаписать всё (backup будет создан)"
        echo "  4) Отмена"
        read -p "Выбор [1]: " INSTALL_MODE
        INSTALL_MODE=${INSTALL_MODE:-1}
        
        case "$INSTALL_MODE" in
            1) echo "  → Additive mode" ;;
            2) echo "  → Merge mode" ;;
            3) 
                echo "  → Overwrite mode"
                FORCE_OVERWRITE=true
                ;;
            *)
                echo "Отменено."
                exit 0
                ;;
        esac
    else
        echo "  → Force mode (--force)"
        INSTALL_MODE=3
    fi
else
    INSTALL_MODE=3  # Нет файлов - можно просто копировать
fi

echo ""

# Спрашиваем данные
read -p "🤖 Имя агента (например: Atlas, Nova, Sage): " AGENT_NAME
AGENT_NAME=${AGENT_NAME:-Agent}

read -p "👤 Имя владельца: " OWNER_NAME
OWNER_NAME=${OWNER_NAME:-User}

read -p "📱 Telegram ID (или пропустить — Enter): " OWNER_ID
OWNER_ID=${OWNER_ID:-000000000}

read -p "📱 Telegram username (без @, или пропустить): " OWNER_TG
OWNER_TG=${OWNER_TG:-username}

read -p "🌍 Таймзона (например: Europe/Moscow, Asia/Tokyo): " TIMEZONE
TIMEZONE=${TIMEZONE:-UTC}

read -p "🎭 Эмодзи агента (например: 🧠, 🤖, ⚡): " EMOJI
EMOJI=${EMOJI:-🤖}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Агент: $AGENT_NAME $EMOJI"
echo "  Владелец: $OWNER_NAME (@$OWNER_TG)"
echo "  Таймзона: $TIMEZONE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Всё верно? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Отменено."
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. Бэкап существующих файлов (ВСЕГДА)
echo ""
echo "📦 Бэкап существующих файлов..."
BACKUP_DIR="$WORKSPACE/.backup-$(date +%Y%m%d-%H%M)"
mkdir -p "$BACKUP_DIR"
BACKED_UP=0
for f in SOUL.md IDENTITY.md USER.md AGENTS.md MEMORY.md TOOLS.md HEARTBEAT.md BOOTSTRAP.md; do
    if [ -f "$WORKSPACE/$f" ]; then
        cp "$WORKSPACE/$f" "$BACKUP_DIR/"
        BACKED_UP=$((BACKED_UP + 1))
    fi
done
if [ $BACKED_UP -gt 0 ]; then
    echo "  ✅ Backup: $BACKUP_DIR ($BACKED_UP файлов)"
else
    echo "  ℹ️  Нет файлов для бэкапа"
fi

# Функция безопасного копирования
safe_copy_file() {
    local src="$1"
    local dst="$2"
    local fname=$(basename "$dst")
    
    if [ -f "$dst" ]; then
        case "$INSTALL_MODE" in
            1)  # Additive - пропускаем
                echo "  ⏭️  Пропускаем (существует): $fname"
                return 0
                ;;
            2)  # Merge - показываем diff
                echo ""
                echo "  📄 $fname уже существует. Различия:"
                diff -u "$dst" "$src" 2>/dev/null | head -30 || true
                echo ""
                read -p "  Заменить? [y/N/d(diff)]: " CHOICE
                case "$CHOICE" in
                    y|Y) cp "$src" "$dst"; echo "  ✅ Заменён: $fname" ;;
                    d|D) diff -u "$dst" "$src" 2>/dev/null || true ;;
                    *) echo "  ⏭️  Пропущен: $fname" ;;
                esac
                ;;
            3)  # Overwrite
                cp "$src" "$dst"
                echo "  ✅ Перезаписан: $fname"
                ;;
        esac
    else
        cp "$src" "$dst"
        echo "  ➕ Добавлен: $fname"
    fi
}

# 2. Копируем файлы workspace
echo ""
echo "📋 Копируем файлы..."
mkdir -p "$WORKSPACE"

# Копируем каждый файл по отдельности
for src_file in "$SCRIPT_DIR/workspace/"*; do
    [ -f "$src_file" ] || continue
    fname=$(basename "$src_file")
    safe_copy_file "$src_file" "$WORKSPACE/$fname"
done

# 3. Создаём структуру памяти (additive - только создаём если нет)
echo ""
echo "🧠 Создаём структуру памяти..."
for dir in daily core decisions projects archive; do
    if [ ! -d "$WORKSPACE/memory/$dir" ]; then
        mkdir -p "$WORKSPACE/memory/$dir"
        echo "  ➕ Создана: memory/$dir"
    else
        echo "  ✅ Существует: memory/$dir"
    fi
done

# 4. Копируем скрипты (ВСЕГДА обновляем - они наши)
echo ""
echo "🔧 Копируем скрипты..."
mkdir -p "$WORKSPACE/scripts"
if [ -d "$SCRIPT_DIR/scripts" ]; then
    for src_script in "$SCRIPT_DIR/scripts/"*.sh; do
        [ -f "$src_script" ] || continue
        fname=$(basename "$src_script")
        cp "$src_script" "$WORKSPACE/scripts/$fname"
        chmod +x "$WORKSPACE/scripts/$fname"
        echo "  ✅ $fname"
    done
fi

# 5. Копируем скиллы (additive)
echo ""
echo "🧬 Копируем скиллы..."
mkdir -p "$WORKSPACE/skills"
if [ -d "$SCRIPT_DIR/skills" ]; then
    for skill_dir in "$SCRIPT_DIR/skills/"*/; do
        [ -d "$skill_dir" ] || continue
        skill_name=$(basename "$skill_dir")
        if [ ! -d "$WORKSPACE/skills/$skill_name" ]; then
            cp -r "$skill_dir" "$WORKSPACE/skills/"
            echo "  ➕ $skill_name"
        else
            echo "  ⏭️  Существует: $skill_name"
        fi
    done
fi

# 6. Заменяем плейсхолдеры
echo ""
echo "✏️  Персонализация..."
find "$WORKSPACE" -name "*.md" -newer "$BACKUP_DIR" -exec sed -i.tmp \
    -e "s/\[AGENT_NAME\]/$AGENT_NAME/g" \
    -e "s/\[OWNER_NAME\]/$OWNER_NAME/g" \
    -e "s/\[OWNER_ID\]/$OWNER_ID/g" \
    -e "s/\[OWNER_TELEGRAM\]/@$OWNER_TG/g" \
    -e "s/\[TRUSTED_USER_ID\]/[не задан]/g" \
    -e "s|\[TIMEZONE\]|$TIMEZONE|g" \
    -e "s/\[GMT_OFFSET\]/$TIMEZONE/g" \
    -e "s/\[EMOJI\]/$EMOJI/g" \
    -e "s/\[PROJECT_NAME\]/[не задан]/g" \
    -e "s/\[CHANNEL_NAME\]/[не задан]/g" \
    -e "s/\[OTHER_AGENT\]/[не задан]/g" \
    -e "s/\[TRUSTED_USER_NAME\]/[не задан]/g" \
    -e "s/\[DOCTOR_BOT_NAME\]/[не задан]/g" \
    -e "s/\[HOST_MACHINE\]/$(hostname)/g" \
    -e "s/\[HOSTNAME\]/$(hostname)/g" \
    -e "s|\[HOME_DIR\]|$HOME|g" \
    {} \; 2>/dev/null || true
find "$WORKSPACE" -name "*.tmp" -delete 2>/dev/null

# Скрипты
find "$WORKSPACE/scripts" -name "*.sh" -exec sed -i.tmp \
    -e "s/\[OWNER_ID\]/$OWNER_ID/g" \
    {} \; 2>/dev/null || true
find "$WORKSPACE/scripts" -name "*.tmp" -delete 2>/dev/null

# 7. SQLite WAL mode
echo ""
echo "💾 Настраиваем SQLite..."
DB="$HOME/.openclaw/memory/main.sqlite"
if [ -f "$DB" ]; then
    MODE=$(sqlite3 "$DB" "PRAGMA journal_mode;" 2>/dev/null)
    if [ "$MODE" != "wal" ]; then
        sqlite3 "$DB" "PRAGMA journal_mode=wal;" 2>/dev/null
        echo "  ✅ WAL mode включен"
    else
        echo "  ✅ WAL mode уже включен"
    fi
    chmod 600 "$DB"
fi

# 8. Права
echo ""
echo "🔒 Настраиваем права..."
chmod 600 "$HOME/.openclaw/openclaw.json" 2>/dev/null || true
echo "  ✅ Права настроены"

# 9. Watchdog (macOS + Linux)
echo ""
echo "🐕 Настройка Smart Watchdog..."
read -p "  Установить автозапуск watchdog? (y/N): " INSTALL_WATCHDOG
if [ "$INSTALL_WATCHDOG" = "y" ] || [ "$INSTALL_WATCHDOG" = "Y" ]; then
    if [ "$(uname)" = "Darwin" ]; then
        # macOS — LaunchAgent
        PLIST="$HOME/Library/LaunchAgents/com.openclaw.watchdog.plist"
        cat > "$PLIST" << PEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.openclaw.watchdog</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$WORKSPACE/scripts/smart-watchdog.sh</string>
  </array>
  <key>StartInterval</key>
  <integer>120</integer>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PEOF
        launchctl unload "$PLIST" 2>/dev/null || true
        launchctl load "$PLIST" 2>/dev/null
        echo "  ✅ Watchdog (LaunchAgent)"
    else
        # Linux — systemd timer
        WATCHDOG_SERVICE="$HOME/.config/systemd/user/openclaw-watchdog.service"
        WATCHDOG_TIMER="$HOME/.config/systemd/user/openclaw-watchdog.timer"
        mkdir -p "$HOME/.config/systemd/user"

        cat > "$WATCHDOG_SERVICE" << SEOF
[Unit]
Description=OpenClaw Smart Watchdog

[Service]
Type=oneshot
ExecStart=/bin/bash $WORKSPACE/scripts/smart-watchdog.sh
SEOF

        cat > "$WATCHDOG_TIMER" << TEOF
[Unit]
Description=OpenClaw Watchdog Timer

[Timer]
OnBootSec=60
OnUnitActiveSec=120

[Install]
WantedBy=timers.target
TEOF

        systemctl --user daemon-reload 2>/dev/null
        systemctl --user enable openclaw-watchdog.timer 2>/dev/null
        systemctl --user start openclaw-watchdog.timer 2>/dev/null
        echo "  ✅ Watchdog (systemd timer)"
    fi
else
    echo "  ⏭️  Watchdog пропущен"
fi

# 10. Голос (опционально, macOS)
if [ "$(uname)" = "Darwin" ]; then
    echo ""
    read -p "🎤 Установить голосовые возможности (Whisper + TTS)? (y/N): " INSTALL_VOICE
    if [ "$INSTALL_VOICE" = "y" ] || [ "$INSTALL_VOICE" = "Y" ]; then
        echo "  Установка может занять 5-10 минут..."
        
        # ffmpeg
        which ffmpeg > /dev/null 2>&1 || brew install ffmpeg 2>/dev/null || echo "  ⚠️  ffmpeg не установлен"
        
        # Python 3.12 + venv
        which python3.12 > /dev/null 2>&1 || brew install python@3.12 2>/dev/null || echo "  ⚠️  python3.12 не установлен"
        
        # mlx-whisper
        if [ ! -d "$HOME/.openclaw/whisper-env" ]; then
            python3.12 -m venv "$HOME/.openclaw/whisper-env" 2>/dev/null || true
            "$HOME/.openclaw/whisper-env/bin/pip" install mlx-whisper edge-tts 2>/dev/null || true
        fi
        
        # Скрипт транскрипции
        cat > "$HOME/.openclaw/whisper-env/transcribe.py" << 'TEOF'
#!/usr/bin/env python3
import sys, mlx_whisper
lang = sys.argv[2] if len(sys.argv) > 2 else "ru"
result = mlx_whisper.transcribe(sys.argv[1], language=lang, path_or_hf_repo="mlx-community/whisper-small-mlx")
for seg in result["segments"]:
    print(seg["text"].strip())
TEOF
        echo "  ✅ Голос установлен"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Установка завершена!"
echo ""
echo "  Агент: $AGENT_NAME $EMOJI"
echo "  Workspace: $WORKSPACE"
echo "  Backup: $BACKUP_DIR"
echo ""
echo "  Что дальше:"
echo "  1. Напишите агенту: 'привет'"
echo "  2. Скажите: 'продиагностируй себя'"
echo "  3. Скажите: 'создай агента' (для клонирования)"
echo ""
echo "  Для отката:"
echo "  cp $BACKUP_DIR/* $WORKSPACE/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
