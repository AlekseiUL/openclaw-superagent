# MEMORY.md - Долгосрочная память агента

> Держать до 3000 символов! Детали в memory/core/

## Факты

### Владелец
- [OWNER_NAME], [OWNER_TELEGRAM], id:[OWNER_ID]
- Таймзона: [GMT_OFFSET]
- Проект [PROJECT_NAME], канал "[CHANNEL_NAME]"
- Второй пользователь: [TRUSTED_USER_NAME], id:[TRUSTED_USER_ID]

### Система
- [HOST_MACHINE] (Apple Silicon), macOS 26.3
- OpenClaw 2026.3.13, Claude Opus 4 через OAuth подписки Max
- Whisper: mlx-whisper (GPU, ~1.5 сек)
- TTS: edge-tts, голос ru-RU-DmitryNeural, pitch -10Hz
- Python 3.12 venv: ~/.openclaw/whisper-env/
- Watchdog: LaunchAgent, проверка каждые 2 мин
- 8 кронов на Sonnet (isolated)

## Решения и уроки
- Имя агента: [AGENT_NAME] ([EMOJI])
- Язык: русский
- Стиль: дружеский, без формальностей
- Кроны только на Sonnet для экономии
- НЕ показывать токены/ключи даже фрагменты
- Проверять auth-profiles.json, не только openclaw.json

## Ожидающее
- Голосовое для Павла (voice_pavel.ogg) - отправить при обращении
