# База знаний проблем OpenClaw

Справочник всех известных проблем и их решений для Agent Doctor.

---

## 🧠 ПАМЯТЬ

### P-001: WAL mode отключен

**Симптомы:**
- Агент не видит недавние записи
- memory_search находит только старые данные
- "Забывает" что было 5-10 минут назад
- stale snapshot warnings в логах

**Диагностика:**
```bash
sqlite3 ~/.openclaw/memory/main.sqlite "PRAGMA journal_mode;"
# Если вернет: delete - ПРОБЛЕМА
```

**Причина:**
SQLite в режиме `delete` делает снимок базы при открытии соединения и не видит изменения от других процессов. WAL (Write-Ahead Log) решает это.

**Решение:**
```bash
sqlite3 ~/.openclaw/memory/main.sqlite "PRAGMA journal_mode=WAL;"
```

**Риск:** Низкий  
**После фикса:** Перезапустить gateway  
**Приоритет:** 🔴 Критичный

---

### P-002: memorySearch отключен

**Симптомы:**
- memory_search tool не работает
- Агент не использует долгосрочную память
- Нет семантического поиска

**Диагностика:**
```bash
jq '.memorySearch.enabled' ~/.openclaw/openclaw.json
# Если false или null - ПРОБЛЕМА
```

**Решение:**
```bash
jq '.memorySearch.enabled = true' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json
```

**Риск:** Средний (нужна проверка конфига)  
**После фикса:** Перезапустить gateway  
**Приоритет:** 🔴 Критичный

---

### P-003: Нет embedding провайдера

**Симптомы:**
- memorySearch включен, но не работает
- Ошибки "no embedding provider configured"
- memory_search возвращает пустые результаты

**Диагностика:**
```bash
jq '.memorySearch.embeddingProvider' ~/.openclaw/openclaw.json
# Если null - ПРОБЛЕМА
```

**Причина:**
Для векторного поиска нужны embeddings от OpenAI, Gemini или Anthropic.

**Решение:**

OpenAI (рекомендуется):
```bash
openclaw auth add openai
# Затем ввести API ключ
```

Gemini:
```bash
openclaw auth add gemini
```

Или вручную в конфиг:
```json
{
  "memorySearch": {
    "enabled": true,
    "embeddingProvider": "openai"
  },
  "auth": {
    "profiles": {
      "openai": {
        "apiKey": "sk-..."
      }
    }
  }
}
```

**Риск:** Низкий  
**После фикса:** Перезапустить gateway  
**Приоритет:** 🔴 Критичный

---

### P-004: Нет MEMORY.md

**Симптомы:**
- Агент не помнит долгосрочные факты
- Нет центрального файла памяти

**Диагностика:**
```bash
ls -lh memory/MEMORY.md
# Если "No such file" - ПРОБЛЕМА
```

**Решение:**
Создать файл:
```bash
cat > memory/MEMORY.md << 'EOF'
# Долгосрочная память

## Важные факты

## Решения

## Паттерны
EOF
```

**Риск:** Низкий  
**Приоритет:** 🟡 Средний

---

### P-005: Нет daily notes

**Симптомы:**
- Нет файлов memory/YYYY-MM-DD.md
- Сессии не архивируются

**Диагностика:**
```bash
ls memory/202*.md 2>/dev/null | wc -l
# Если 0 - ПРОБЛЕМА
```

**Решение:**
Создать структуру:
```bash
date_today=$(date +%Y-%m-%d)
cat > memory/${date_today}.md << 'EOF'
# $(date +%Y-%m-%d)

## Что сделано

## Решения и почему

## Связи дня

## Открыто
EOF
```

**Риск:** Низкий  
**Приоритет:** 🟡 Средний

---

### P-006: Нет структуры папок

**Симптомы:**
- Нет memory/core/, memory/decisions/, memory/projects/

**Диагностика:**
```bash
ls -d memory/core memory/decisions memory/projects 2>/dev/null
# Если ошибки - ПРОБЛЕМА
```

**Решение:**
```bash
mkdir -p memory/core memory/decisions memory/projects
```

**Риск:** Низкий  
**Приоритет:** 🟢 Низкий

---

### P-007: База данных отсутствует

**Симптомы:**
- Нет ~/.openclaw/memory/*.sqlite
- Ошибки при запуске

**Диагностика:**
```bash
ls ~/.openclaw/memory/*.sqlite
# Если "No such file" - ПРОБЛЕМА
```

**Причина:**
Свежая установка или поврежденная база.

**Решение:**
```bash
# База создастся автоматически при первом запуске
openclaw gateway restart
```

Если не помогло - переустановка:
```bash
npm uninstall -g openclaw
npm install -g openclaw
openclaw init
```

**Риск:** Высокий (потеря данных!)  
**Приоритет:** 🔴 Критичный

---

### P-008: База огромная (>500MB)

**Симптомы:**
- Медленный поиск
- Высокое использование RAM
- Долгий старт gateway

**Диагностика:**
```bash
ls -lh ~/.openclaw/memory/*.sqlite
# Если >500MB - стоит почистить
```

**Решение:**
```bash
# ОПАСНО! Делать backup перед!
cp ~/.openclaw/memory/main.sqlite ~/.openclaw/memory/main.sqlite.backup

# Вакуум базы
sqlite3 ~/.openclaw/memory/main.sqlite "VACUUM;"

# Удалить старые чанки (>90 дней)
sqlite3 ~/.openclaw/memory/main.sqlite "DELETE FROM memory_chunks WHERE timestamp < datetime('now', '-90 days');"
sqlite3 ~/.openclaw/memory/main.sqlite "VACUUM;"
```

**Риск:** Высокий (нужен backup!)  
**Приоритет:** 🟡 Средний

---

## ⏰ КРОНЫ

### P-009: Крон отключен

**Симптомы:**
- Крон в списке, но не запускается
- enabled = false

**Диагностика:**
```bash
openclaw cron list --json | jq '.[] | select(.enabled==false)'
```

**Решение:**
```bash
openclaw cron enable <cron-name>
```

**Риск:** Низкий  
**Приоритет:** 🟡 Средний

---

### P-010: Крон падает при запуске

**Симптомы:**
- failureCount > 0
- lastError не пустой
- Ошибки в логах

**Диагностика:**
```bash
openclaw cron logs <cron-name>
```

**Типичные причины:**
1. Модель не указана полным путем
2. API ключ отсутствует
3. Синтаксическая ошибка в payload

**Решение:**

Модель:
```bash
openclaw cron edit <name> --model "anthropic/claude-sonnet-4-6"
```

API ключ:
```bash
openclaw auth add <provider>
```

Payload:
```bash
openclaw cron show <name>
# Проверить JSON валидность
```

**Риск:** Средний  
**Приоритет:** 🟡 Средний

---

### P-011: Крон не запускается по расписанию

**Симптомы:**
- Крон включен
- Нет ошибок
- Но lastRun давно или null

**Диагностика:**
```bash
openclaw cron list --json | jq '.[] | {name, lastRun, schedule}'
```

**Причина:**
Gateway упал или перезагружался во время запуска.

**Решение:**
```bash
# Запустить вручную для теста
openclaw cron run <name>

# Если работает - проблема в планировщике
openclaw gateway restart
```

**Риск:** Низкий  
**Приоритет:** 🟡 Средний

---

## ⚙️ КОНФИГ

### P-012: Битый JSON в конфиге

**Симптомы:**
- Gateway не запускается
- Ошибки парсинга JSON

**Диагностика:**
```bash
jq empty ~/.openclaw/openclaw.json
# Если ошибка - ПРОБЛЕМА
```

**Решение:**

Найти ошибку:
```bash
jq . ~/.openclaw/openclaw.json
# Покажет строку с ошибкой
```

Восстановить из бэкапа:
```bash
cp ~/.openclaw/openclaw.json.backup ~/.openclaw/openclaw.json
```

Или пересоздать:
```bash
mv ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.broken
openclaw init
# Настроить заново
```

**Риск:** Высокий (нужен backup!)  
**Приоритет:** 🔴 Критичный

---

### P-013: Модель не настроена

**Симптомы:**
- Ошибки "no model configured"
- Агент не отвечает

**Диагностика:**
```bash
jq '.defaultModel' ~/.openclaw/openclaw.json
# Если null - ПРОБЛЕМА
```

**Решение:**
```bash
jq '.defaultModel = "anthropic/claude-opus-4-6"' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json
```

**Риск:** Низкий  
**После фикса:** Перезапустить gateway  
**Приоритет:** 🔴 Критичный

---

### P-014: memory-core отключен

**Симптомы:**
- После обновления OpenClaw память перестала работать
- memorySearch не работает даже если enabled = true

**Диагностика:**
```bash
jq '.plugins[] | select(.name=="memory-core") | .enabled' ~/.openclaw/openclaw.json
# Если false или null - ПРОБЛЕМА
```

**Причина:**
После обновления OpenClaw плагины могут сбрасываться.

**Решение:**
```bash
jq '.plugins = [.plugins[] | if .name == "memory-core" then .enabled = true else . end]' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json
```

**Риск:** Средний  
**После фикса:** Перезапустить gateway  
**Приоритет:** 🔴 Критичный

---

### P-015: Telegram/Discord не подключен

**Симптомы:**
- Нет ответов в Telegram/Discord
- Ошибки подключения

**Диагностика:**
```bash
jq '.telegram.enabled, .discord.enabled' ~/.openclaw/openclaw.json
# Оба false - ПРОБЛЕМА
```

**Решение:**

Telegram:
```bash
# Получить токен от @BotFather
openclaw config set telegram.enabled true
openclaw config set telegram.token "YOUR_TOKEN"
```

Discord:
```bash
# Получить токен из Discord Developer Portal
openclaw config set discord.enabled true
openclaw config set discord.token "YOUR_TOKEN"
```

**Риск:** Низкий  
**После фикса:** Перезапустить gateway  
**Приоритет:** 🟡 Средний

---

## 📁 ФАЙЛЫ

### P-016: Нет SOUL.md

**Симптомы:**
- Агент безличный, формальный
- Нет уникальной личности

**Решение:**
Создать SOUL.md с описанием личности агента.

**Риск:** Низкий  
**Приоритет:** 🟡 Средний

---

### P-017: Нет USER.md

**Симптомы:**
- Агент не знает о пользователе
- Нет контекста о владельце

**Решение:**
Создать USER.md с информацией о себе.

**Риск:** Низкий  
**Приоритет:** 🟡 Средний

---

### P-018: Skills не читаются

**Симптомы:**
- Ошибки "Permission denied" при чтении SKILL.md
- Skills не загружаются

**Диагностика:**
```bash
find skills -name "SKILL.md" -exec ls -l {} \;
# Проверить права доступа
```

**Решение:**
```bash
chmod -R 755 skills/
find skills -name "*.md" -exec chmod 644 {} \;
```

**Риск:** Низкий  
**Приоритет:** 🟢 Низкий

---

## 🔧 GATEWAY

### P-019: Gateway не запущен

**Симптомы:**
- openclaw status → "not running"
- Нет ответов от агента

**Диагностика:**
```bash
openclaw status
```

**Решение:**
```bash
openclaw gateway start
```

Если не запускается - смотреть логи:
```bash
tail -50 ~/.openclaw/logs/gateway.log
```

**Риск:** Низкий  
**Приоритет:** 🔴 Критичный

---

### P-020: Порт занят

**Симптомы:**
- Gateway не запускается
- Ошибка "port already in use"

**Диагностика:**
```bash
lsof -i :3000
# Показать процесс на порту 3000
```

**Решение:**

Убить процесс:
```bash
lsof -ti:3000 | xargs kill -9
openclaw gateway start
```

Или сменить порт:
```bash
jq '.gateway.port = 3001' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json
openclaw gateway start
```

**Риск:** Низкий  
**Приоритет:** 🟡 Средний

---

### P-021: Ошибки в логах

**Симптомы:**
- Странное поведение
- Периодические падения

**Диагностика:**
```bash
tail -100 ~/.openclaw/logs/gateway.log | grep -i "error"
```

**Решение:**
Зависит от конкретной ошибки. Типичные:

1. "ECONNREFUSED" - провайдер API недоступен
2. "ETIMEDOUT" - таймаут запроса
3. "401 Unauthorized" - неверный API ключ
4. "429 Too Many Requests" - превышен лимит

**Риск:** Средний  
**Приоритет:** 🟡 Средний

---

## 💾 СИСТЕМА

### P-022: Старая версия Node.js

**Требование:** Node.js >= 20.0.0

**Симптомы:**
- Gateway не запускается
- Ошибки "Unsupported engine"
- Проблемы с зависимостями

**Диагностика:**
```bash
node --version
# Если < v20 - ПРОБЛЕМА
```

**Решение:**

macOS:
```bash
brew upgrade node
```

Linux (nvm):
```bash
nvm install 20
nvm use 20
nvm alias default 20
```

Linux (apt):
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

Windows:
```
Скачать с nodejs.org
Или через nvm-windows
```

**Риск:** Средний (может потребовать переустановку OpenClaw)  
**Приоритет:** 🔴 Критичный

---

### P-023: Старая версия Python

**Требование:** Python >= 3.11

**Симптомы:**
- Ошибки при запуске Python-скиллов
- Проблемы с зависимостями

**Диагностика:**
```bash
python3 --version
# Если < 3.11 - ПРОБЛЕМА
```

**Решение:**

macOS:
```bash
brew install python@3.12
```

Linux:
```bash
sudo apt install python3.12
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
```

Windows:
```
Скачать с python.org
```

**Риск:** Средний  
**Приоритет:** 🟡 Средний

---

### P-024: Диск заполнен

**Симптомы:**
- Ошибки записи
- База данных не растет
- Кроны падают
- "No space left on device"

**Диагностика:**
```bash
df -h ~
# Если Available < 1GB - ПРОБЛЕМА
```

**Решение:**

1. Очистить логи:
```bash
rm -rf ~/.openclaw/logs/*.log.old
rm -rf ~/.openclaw/logs/*.log.*.gz
```

2. Очистить кеш:
```bash
rm -rf ~/.openclaw/cache/*
```

3. Очистить старые бэкапы:
```bash
find ~/.openclaw/backups -mtime +30 -delete
```

4. Вакуум базы данных:
```bash
sqlite3 ~/.openclaw/memory/main.sqlite "VACUUM;"
```

5. Удалить старые session логи:
```bash
find ~/.openclaw/sessions -name "*.log" -mtime +7 -delete
```

**Риск:** Низкий (файлы которые можно удалять)  
**Приоритет:** 🔴 Критичный

---

### P-025: Устаревшая версия OpenClaw

**Симптомы:**
- Баги которые исправлены в новой версии
- Нет новых фич

**Диагностика:**
```bash
openclaw --version
npm view openclaw version
# Сравнить
```

**Решение:**
```bash
npm update -g openclaw
bash scripts/post-update.sh
```

**Риск:** Средний (может сломать конфиг)  
**После:** Запустить диагностику!  
**Приоритет:** 🟡 Средний

---

## 🛡️ БЕЗОПАСНОСТЬ

### P-026: Gateway bind = 0.0.0.0

**ОПАСНОСТЬ:** Gateway доступен из интернета!

**Симптомы:**
- Любой может подключиться к вашему агенту
- Риск утечки данных

**Диагностика:**
```bash
jq '.gateway.bind' ~/.openclaw/openclaw.json
# Если "0.0.0.0" - ОПАСНО!
```

**Решение:**
```bash
jq '.gateway.bind = "127.0.0.1"' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json
```

**Риск:** Низкий (но критично исправить!)  
**После фикса:** Перезапустить gateway  
**Приоритет:** 🔴 Критичный

---

### P-027: Нет auth token

**Симптомы:**
- Gateway без защиты
- Любой локальный процесс может подключиться

**Диагностика:**
```bash
jq '.gateway.authMode' ~/.openclaw/openclaw.json
# Если null или "none" - ПРОБЛЕМА
```

**Решение:**
```bash
jq '.gateway.authMode = "token"' ~/.openclaw/openclaw.json > /tmp/config.json && mv /tmp/config.json ~/.openclaw/openclaw.json
openclaw gateway restart
# Gateway создаст токен автоматически
```

**Риск:** Низкий  
**Приоритет:** 🟡 Средний

---

### P-028: API ключи в файлах памяти

**ОПАСНОСТЬ:** Утечка секретов!

**Диагностика:**
```bash
grep -r "sk-" memory/ 2>/dev/null
grep -r "apiKey" memory/ 2>/dev/null
# Если нашло - ОПАСНО!
```

**Решение:**

1. Найти и удалить:
```bash
grep -r "sk-" memory/ -l | xargs -I {} echo "ПРОБЛЕМА: {}"
```

2. Вручную отредактировать файлы
3. Ревокнуть скомпрометированные ключи!
4. Создать новые

**Риск:** Высокий  
**Приоритет:** 🔴 Критичный

---

## Статистика проблем

**По приоритету:**
- 🔴 Критичный: 12 проблем
- 🟡 Средний: 12 проблем
- 🟢 Низкий: 4 проблемы

**По категориям:**
- 🧠 Память: 8 проблем
- ⏰ Кроны: 3 проблемы
- ⚙️ Конфиг: 4 проблемы
- 📁 Файлы: 3 проблемы
- 🔧 Gateway: 3 проблемы
- 💾 Система: 4 проблемы
- 🛡️ Безопасность: 3 проблемы

---

**Версия базы:** 1.0.0  
**Последнее обновление:** 2026-03-06  
**Всего проблем:** 28
