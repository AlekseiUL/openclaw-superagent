# Handoff — тест compaction (2026-03-24 16:50)

## Тема
Тестирование compaction и цепочки восстановления

## Что обсуждали
- Диагностика системы Agent Doctor
- Оптимизация кронов (27 → 12 запусков/день)
- Установка OpenAI embeddings — память работает (238 chunks)
- WAL mode слетает — нашли причину (OpenClaw не ставит WAL), поставили ensure-wal LaunchAgent
- Smart watchdog заменил простой watchdog

## Решения
- Self-Heal каждые 6ч (было 2ч)
- Agent Doctor раз в неделю вместо ежедневного Security Audit
- Daily notes в memory/daily/, архив >90 дней удаляется
- WAL гарантируется тремя слоями защиты

## TODO
- Заполнить memory/core/ долгосрочными фактами
- Настроить git remote для offsite бэкапа
- Подключить VNC для доступа к Claude лимитам
