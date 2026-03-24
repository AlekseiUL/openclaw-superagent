#!/bin/bash
# Auto-diagnostic script для OpenClaw
# Можно запускать из крона или вручную
# Версия: 1.0.0

set -e

OPENCLAW_DIR="$HOME/.openclaw"
MEMORY_DIR="${OPENCLAW_DIR}/memory"
CONFIG="${OPENCLAW_DIR}/openclaw.json"

echo "🏥 AGENT DOCTOR - Автодиагностика"
echo "================================"
echo ""

# Цвета для вывода
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

ISSUES=0

# Функция для проверки
check() {
    local name="$1"
    local command="$2"
    local expected="$3"
    
    echo -n "Проверка: $name... "
    
    if result=$(eval "$command" 2>&1); then
        if [[ "$expected" == "" ]] || [[ "$result" == *"$expected"* ]]; then
            echo -e "${GREEN}✅ OK${NC}"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC}"
            echo "   Ожидалось: $expected"
            echo "   Получено: $result"
            ((ISSUES++))
            return 1
        fi
    else
        echo -e "${RED}❌ ERROR${NC}"
        echo "   $result"
        ((ISSUES++))
        return 1
    fi
}

# 1. Память
echo "🧠 ПАМЯТЬ"
echo "--------"

check "SQLite база существует" \
    "ls ${MEMORY_DIR}/*.sqlite" \
    "main.sqlite"

check "WAL mode включен" \
    "sqlite3 ${MEMORY_DIR}/main.sqlite 'PRAGMA journal_mode;'" \
    "wal"

check "Есть записи в базе" \
    "sqlite3 ${MEMORY_DIR}/main.sqlite 'SELECT COUNT(*) FROM memory_chunks;'" \
    ""

check "memorySearch включен" \
    "jq -r '.memorySearch.enabled' $CONFIG" \
    "true"

check "Embedding provider настроен" \
    "jq -r '.memorySearch.embeddingProvider' $CONFIG" \
    ""

echo ""

# 2. Кроны
echo "⏰ КРОНЫ"
echo "-------"

if command -v openclaw &> /dev/null; then
    check "Список кронов доступен" \
        "openclaw cron list --json | jq 'length'" \
        ""
else
    echo -e "${YELLOW}⚠️  openclaw CLI недоступен${NC}"
    ((ISSUES++))
fi

echo ""

# 3. Конфиг
echo "⚙️ КОНФИГ"
echo "--------"

check "openclaw.json валидный" \
    "jq empty $CONFIG" \
    ""

check "Модель настроена" \
    "jq -r '.defaultModel' $CONFIG" \
    ""

check "memory-core включен" \
    "jq '.plugins[] | select(.name==\"memory-core\") | .enabled' $CONFIG" \
    "true"

echo ""

# 4. Gateway
echo "🔧 GATEWAY"
echo "---------"

if command -v openclaw &> /dev/null; then
    check "Gateway запущен" \
        "openclaw status" \
        "running"
else
    echo -e "${YELLOW}⚠️  Не могу проверить статус${NC}"
fi

echo ""

# 5. Система
echo "💾 СИСТЕМА"
echo "---------"

check "Node.js версия >= 20" \
    "node --version" \
    "v2"

check "Python >= 3.11" \
    "python3 --version" \
    "3.1"

# Свободное место (минимум 1GB)
free_space=$(df -k ~ | tail -1 | awk '{print $4}')
free_gb=$((free_space / 1024 / 1024))
if [[ $free_gb -ge 1 ]]; then
    echo -e "Проверка: Свободное место... ${GREEN}✅ OK${NC} (${free_gb}GB)"
else
    echo -e "Проверка: Свободное место... ${RED}❌ МАЛО${NC} (${free_gb}GB)"
    ((ISSUES++))
fi

echo ""

# 6. Безопасность
echo "🛡️ БЕЗОПАСНОСТЬ"
echo "--------------"

bind=$(jq -r '.gateway.bind // "127.0.0.1"' $CONFIG)
if [[ "$bind" == "0.0.0.0" ]]; then
    echo -e "Проверка: Gateway bind... ${RED}❌ ОПАСНО${NC} (публичный доступ!)"
    ((ISSUES++))
else
    echo -e "Проверка: Gateway bind... ${GREEN}✅ OK${NC} ($bind)"
fi

# Проверка ключей в файлах
key_leaks=$(grep -r "sk-" memory/ 2>/dev/null | wc -l | tr -d ' ')
if [[ "$key_leaks" -gt 0 ]]; then
    echo -e "Проверка: API ключи в памяти... ${RED}❌ НАЙДЕНЫ${NC} ($key_leaks)"
    ((ISSUES++))
else
    echo -e "Проверка: API ключи в памяти... ${GREEN}✅ OK${NC}"
fi

echo ""
echo "================================"

if [[ $ISSUES -eq 0 ]]; then
    echo -e "${GREEN}✅ Все проверки пройдены!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Найдено проблем: $ISSUES${NC}"
    echo ""
    echo "Запустите полную диагностику:"
    echo "  Скажите агенту: 'продиагностируй себя'"
    exit 1
fi
