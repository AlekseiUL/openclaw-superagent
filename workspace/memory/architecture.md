# Архитектура [AGENT_NAME] — самоописание

## Кто я
- Имя: [AGENT_NAME] [EMOJI]
- Роль: Главный агент, управляющий другими агентами
- Платформа: OpenClaw на [HOST_MACHINE] (Apple Silicon)
- Модель: Claude Opus 4.6, подписка Max ($100)
- Канал: Telegram ([OWNER_TELEGRAM])

## Компоненты

### Память
- MEMORY.md — рабочая (грузится каждый раз, <3000B)
- memory/daily/ — дневники (архивация >14д, удаление >90д)
- memory/core/ — вечные факты
- memory/decisions/ — решения и уроки
- memory/patterns.md — паттерны самообучения
- memory/projects-log.md — история задач
- memory/handoff.md — передача контекста
- SQLite + OpenAI embeddings — векторный поиск (hybrid)

### Кроны (9)
Self-Heal (6ч), Memory Hygiene (03:30), VectorDB Cleanup (03:15),
Config Backup (04:30), Agent Doctor (пн 05:00), Утренний отчёт (09:00),
Diary Check (21:00), Git Auto-Commit (22:00), Cron Cleanup (вс 03:00)

### Защита
- Smart watchdog (каждые 2 мин) — WAL, конфиг, диск, порт, алерт
- Pre-restart handoff — сохраняет контекст перед перезапуском
- Post-update check — проверка после обновления
- 3 документа правил (Security, Honesty, OWASP guide)
- Gateway: loopback, права 600

### Инструменты
- STT: mlx-whisper (GPU, ~1.5с)
- TTS: edge-tts (ru-RU-DmitryNeural)
- Браузеры: Chrome, agent-browser, Lightpanda
- Поиск: Perplexity Sonar + web_fetch

### Агенты
- Doktor[AGENT_NAME] (@Doktor[AGENT_NAME]_bot) — ClaudeClaw, Claude Opus, взаимный доступ

### Скиллы
- agent-doctor — самодиагностика (7 категорий, 28 проблем)
- agent-forge — создание новых агентов и скиллов

## Самообучение
Ошибка → patterns.md → 3 повтора → правило в lessons-learned.md
