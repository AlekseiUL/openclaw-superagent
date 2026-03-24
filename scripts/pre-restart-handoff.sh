#!/bin/bash
# Pre-restart handoff: сохраняет контекст перед перезапуском gateway
# Вызывается watchdog'ом ПЕРЕД перезапуском

HANDOFF_FILE="$HOME/.openclaw/workspace/memory/handoff.md"
DATE=$(date +%Y-%m-%d_%H:%M)
SESSION_DIR="$HOME/.openclaw/agents/main/sessions"

# Находим последнюю активную сессию
LATEST_SESSION=$(ls -t "$SESSION_DIR"/*.jsonl 2>/dev/null | head -1)

if [ -n "$LATEST_SESSION" ]; then
    # Извлекаем последние сообщения из сессии
    LAST_MESSAGES=$(tail -20 "$LATEST_SESSION" 2>/dev/null | grep -o '"content":"[^"]*"' | tail -5)
    
    cat > "$HANDOFF_FILE" << EOF
# Handoff - автоматический ($DATE)
## Причина: перезапуск gateway

## Последняя активная сессия
Файл: $(basename "$LATEST_SESSION")

## Контекст
Gateway был перезапущен. Контекст предыдущей сессии потерян.
Прочитай memory/$(date +%Y-%m-%d).md для восстановления контекста.

## Статус системы на момент перезапуска
- Диск: $(df -h / | tail -1 | awk '{print $5}') использовано
- Uptime: $(uptime | awk '{print $3, $4}')
EOF
    echo "Handoff записан: $HANDOFF_FILE"
else
    echo "Нет активных сессий"
fi
