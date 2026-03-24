# DO_NOT_DELETE.md - Защита от удаления

## Критичные файлы (НИКОГДА не удалять)

### Workspace
- IDENTITY.md, SOUL.md, USER.md, AGENTS.md, MEMORY.md
- TOOLS.md, HEARTBEAT.md, BOOTSTRAP.md
- SECURITY-RULES.md, HONESTY-RULES.md
- ~/.openclaw/openclaw.json

### Память
- memory/core/* (вечные факты)
- memory/decisions/* (решения и уроки)
- memory/projects/* (проекты)
- memory/handoff.md (передача контекста)
- memory/patterns.md (самообучение)
- memory/projects-log.md (история задач)
- memory/architecture.md (самоописание)
- memory/DO_NOT_DELETE.md (этот файл)

### Скиллы
- skills/**/*.md (все скиллы)

## Разрешено удалять

- memory/daily/*.md старше 90 дней (после архивации!)
- memory/archive/*.md старше 90 дней (уже в векторной базе)
- *.bak старше 30 дней
- *.tmp
- .DS_Store

## Правило

Перед удалением ЛЮБОГО файла - сверься с этим списком.
Если файла нет в "Разрешено удалять" - спроси владельца.
Удаляй через trash, не через rm -rf.
