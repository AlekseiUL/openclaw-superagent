# Thoth System — Complete AI Agent System for OpenClaw

Turn a blank OpenClaw into a fully-featured AI agent with memory, self-diagnostics, self-improvement, voice support, and automation — in 2 minutes.

## What You Get

- **Persistent Memory** — file-based + vector search. Agent remembers everything across sessions
- **Self-Healing** — smart watchdog monitors gateway, SQLite WAL, fixes issues automatically
- **Handoff System** — context saved before compaction, restored on wake. Agent never "forgets"
- **Security Rules** — data never leaks, ports locked, tokens protected
- **Honesty Rules** — agent never fabricates facts, admits mistakes immediately
- **3 Auto-Crons** — daily backup, morning briefing, evening diary
- **2 Built-in Skills** — Agent Doctor (self-diagnostics) + Agent Forge (create new skills)
- **Voice Support** — local Whisper transcription (no API keys needed)
- **Interactive Setup** — installer asks your name, agent name, timezone. Personalizes everything

## Requirements

- OpenClaw (any 2026+ version)
- Any LLM (Claude, OpenAI, Gemini)
- macOS or Linux
- Node.js 20+

## Installation (2 minutes)

```bash
git clone https://github.com/AlekseiUL/thoth-system.git
cd thoth-system
bash install.sh
```

The installer will ask:
- Agent name
- Your name
- Telegram ID (optional)
- Timezone

Everything is configured automatically.

## What's Inside

```
thoth-system/
  workspace/                    # Agent brain
    SOUL.md                     # Personality, values, communication style
    IDENTITY.md                 # Name, role
    AGENTS.md                   # Work rules, security, memory management
    TOOLS.md                    # Available tools and configurations
    MEMORY.md                   # Long-term facts
    USER.md                     # Owner information
    BOOTSTRAP.md                # Wake-up instructions
    HEARTBEAT.md                # Proactive checks schedule
    SECURITY-RULES.md           # Data protection rules
    HONESTY-RULES.md            # No-fabrication policy
    memory/
      handoff.md                # Context transfer between sessions
      decisions/lessons-learned.md  # Self-improvement log
      patterns.md               # Recurring pattern detection
      architecture.md           # System architecture reference
      DO_NOT_DELETE.md          # Protected files list
  scripts/
    smart-watchdog.sh           # Auto-healing: WAL + gateway monitoring
    post-update-check.sh        # Post-update verification
    pre-restart-handoff.sh      # Save context before restart
  skills/
    agent-doctor/               # Self-diagnostics skill
    agent-forge/                # Skill creation skill
  install.sh                    # Interactive installer
```

## Self-Improvement System

The agent learns from mistakes:

1. **Lessons Learned** — every correction is logged in `memory/decisions/lessons-learned.md`
2. **Graduation** — if the same mistake happens 3+ times, the lesson is promoted to SOUL.md permanently
3. **Patterns** — recurring issues are tracked in `memory/patterns.md` with automation proposals

## Security

- Gateway bound to `loopback` (127.0.0.1) — not accessible from outside
- API keys only in `.env`, never in config or logs
- `allowFrom` restricts Telegram access to owner only
- No data sent externally without explicit permission
- Files deleted to trash, never permanently

## After Installation

The agent will:
1. Ask you 5 questions to personalize SOUL.md
2. Set up memory structure
3. Configure compaction with context preservation
4. Start 3 automatic crons (backup, morning check, evening diary)
5. Report what's done and what needs manual setup

---

# Thoth System — Полная система AI-агента для OpenClaw

Превращает пустой OpenClaw в полноценного AI-агента с памятью, самодиагностикой, самообучением, голосом и автоматикой — за 2 минуты.

## Что получаете

- **Постоянная память** — файловая + векторный поиск. Агент помнит всё между сессиями
- **Самовосстановление** — watchdog следит за gateway, SQLite WAL, чинит проблемы автоматически
- **Система handoff** — контекст сохраняется перед компактификацией, восстанавливается при пробуждении
- **Правила безопасности** — данные не утекают, порты закрыты, токены защищены
- **Правила честности** — агент не выдумывает, признаёт ошибки сразу
- **3 автокрона** — ежедневный бэкап, утренняя сводка, вечерний дневник
- **2 встроенных скилла** — Агент-доктор (самодиагностика) + Агент-кузница (создание скиллов)
- **Голос** — локальный Whisper (без API ключей)
- **Интерактивная установка** — установщик спрашивает имя, таймзону, персонализирует всё

## Требования

- OpenClaw (любая версия 2026+)
- Любая модель (Claude, OpenAI, Gemini)
- macOS или Linux
- Node.js 20+

## Установка (2 минуты)

```bash
git clone https://github.com/AlekseiUL/thoth-system.git
cd thoth-system
bash install.sh
```

Установщик спросит имя агента, ваше имя, Telegram ID и таймзону. Всё настроит автоматически.

## Система самосовершенствования

1. **Уроки** — каждая ошибка записывается в `memory/decisions/lessons-learned.md`
2. **Graduation** — ошибка 3+ раза → правило навсегда в SOUL.md
3. **Паттерны** — повторяющиеся проблемы отслеживаются с предложением автоматизации

## Безопасность

- Gateway на loopback — недоступен извне
- API ключи только в .env
- allowFrom ограничивает доступ к боту
- Данные наружу — только с разрешения
- Удаление — только в корзину

---

## Resources | Ресурсы

- 📺 YouTube: [youtube.com/@alekseiulianov](https://youtube.com/@alekseiulianov)
- 📱 Telegram: [t.me/Sprut_AI](https://t.me/Sprut_AI)
- 🔥 AI ОПЕРАЦИОНКА (Premium): [Подписка](https://t.me/tribute/app?startapp=sJyg) — продвинутые материалы, скиллы, агенты, поддержка
- 💻 GitHub: [github.com/AlekseiUL](https://github.com/AlekseiUL)

## License

MIT

---

*Built with real-world experience. Every rule = a real lesson learned.*
*Создано на основе реального опыта. Каждое правило = реальный урок.*
