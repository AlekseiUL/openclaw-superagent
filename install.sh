#!/bin/bash
# Thoth System Installer — устанавливает полную систему агента в существующий OpenClaw
# Работает на macOS и Linux

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🏗️  Thoth System Installer"
echo "  Полная система AI-агента для OpenClaw"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Определяем workspace
OPENCLAW_DIR="$HOME/.openclaw"
if [ ! -d "$OPENCLAW_DIR" ]; then
    echo "❌ OpenClaw не найден ($OPENCLAW_DIR)"
    echo "Установите OpenClaw сначала: npm install -g openclaw && openclaw setup"
    exit 1
fi

# Ищем workspace
WORKSPACE=$(python3 -c "
import json, os
try:
    d = json.load(open(os.path.expanduser('~/.openclaw/openclaw.json')))
    ws = d.get('agents',{}).get('defaults',{}).get('workspace','')
    print(ws if ws else os.path.expanduser('~/.openclaw/workspace'))
except:
    print(os.path.expanduser('~/.openclaw/workspace'))
" 2>/dev/null)

if [ ! -d "$WORKSPACE" ]; then
    WORKSPACE="$HOME/.openclaw/workspace"
fi

echo "📂 Workspace: $WORKSPACE"
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

# 1. Бэкап существующих файлов
echo ""
echo "📦 Бэкап существующих файлов..."
BACKUP_DIR="$WORKSPACE/.backup-$(date +%Y%m%d-%H%M)"
mkdir -p "$BACKUP_DIR"
for f in SOUL.md IDENTITY.md USER.md AGENTS.md MEMORY.md TOOLS.md HEARTBEAT.md BOOTSTRAP.md; do
    [ -f "$WORKSPACE/$f" ] && cp "$WORKSPACE/$f" "$BACKUP_DIR/"
done
echo "  Бэкап: $BACKUP_DIR"

# 2. Копируем файлы
echo "📋 Копируем файлы..."
cp -r "$SCRIPT_DIR/workspace/"* "$WORKSPACE/"

# 3. Создаём структуру памяти
echo "🧠 Создаём структуру памяти..."
mkdir -p "$WORKSPACE/memory/"{daily,core,decisions,projects,archive}

# 4. Копируем скрипты
echo "🔧 Копируем скрипты..."
mkdir -p "$WORKSPACE/scripts"
cp "$SCRIPT_DIR/scripts/"*.sh "$WORKSPACE/scripts/" 2>/dev/null
chmod +x "$WORKSPACE/scripts/"*.sh 2>/dev/null

# 5. Копируем скиллы
echo "🧬 Копируем скиллы..."
mkdir -p "$WORKSPACE/skills"
cp -r "$SCRIPT_DIR/skills/"* "$WORKSPACE/skills/" 2>/dev/null

# 6. Заменяем плейсхолдеры
echo "✏️  Персонализация..."
find "$WORKSPACE" -name "*.md" -exec sed -i.tmp \
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
    {} \;
find "$WORKSPACE" -name "*.tmp" -delete 2>/dev/null

# Скрипты
find "$WORKSPACE/scripts" -name "*.sh" -exec sed -i.tmp \
    -e "s/\[OWNER_ID\]/$OWNER_ID/g" \
    {} \;
find "$WORKSPACE/scripts" -name "*.tmp" -delete 2>/dev/null

# 7. SQLite WAL mode
echo "💾 Настраиваем SQLite..."
DB="$HOME/.openclaw/memory/main.sqlite"
if [ -f "$DB" ]; then
    sqlite3 "$DB" "PRAGMA journal_mode=wal;" 2>/dev/null
    chmod 600 "$DB"
fi

# 8. Права
echo "🔒 Настраиваем права..."
chmod 600 "$HOME/.openclaw/openclaw.json" 2>/dev/null

# 9. Watchdog (macOS + Linux)
echo "🐕 Устанавливаем Smart Watchdog..."
sed -i.tmp "s|\$HOME|$HOME|g" "$WORKSPACE/scripts/smart-watchdog.sh" 2>/dev/null
rm "$WORKSPACE/scripts/smart-watchdog.sh.tmp" 2>/dev/null

if [ "$(uname)" = "Darwin" ]; then
    # macOS — LaunchAgent
    cat > "$HOME/Library/LaunchAgents/com.openclaw.watchdog.plist" << PEOF
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
    launchctl load "$HOME/Library/LaunchAgents/com.openclaw.watchdog.plist" 2>/dev/null
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

# 10. Голос (опционально, macOS)
if [ "$(uname)" = "Darwin" ]; then
    echo ""
    read -p "🎤 Установить голосовые возможности (Whisper + TTS)? (y/n): " INSTALL_VOICE
    if [ "$INSTALL_VOICE" = "y" ] || [ "$INSTALL_VOICE" = "Y" ]; then
        echo "  Установка может занять 5-10 минут..."
        
        # ffmpeg
        which ffmpeg > /dev/null 2>&1 || brew install ffmpeg 2>/dev/null
        
        # Python 3.12 + venv
        which python3.12 > /dev/null 2>&1 || brew install python@3.12 2>/dev/null
        
        # mlx-whisper
        if [ ! -d "$HOME/.openclaw/whisper-env" ]; then
            python3.12 -m venv "$HOME/.openclaw/whisper-env"
            "$HOME/.openclaw/whisper-env/bin/pip" install mlx-whisper edge-tts 2>/dev/null
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
echo ""
echo "  Что дальше:"
echo "  1. Напишите агенту: 'привет'"
echo "  2. Скажите: 'продиагностируй себя'"
echo "  3. Скажите: 'создай агента' (для клонирования)"
echo ""
echo "  Кроны установятся автоматически при первом"
echo "  heartbeat или создайте вручную."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
