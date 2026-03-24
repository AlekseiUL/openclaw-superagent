# Установка Agent Doctor

Быстрая установка скилла самодиагностики для OpenClaw.

---

## Требования

- OpenClaw установлен и настроен
- Git (опционально, для клонирования)

---

## Вариант 1: Через Git (рекомендуется)

```bash
# 1. Перейти в workspace OpenClaw
cd ~/path/to/your/workspace  # замените на свой путь

# 2. Если skills/ нет - создать
mkdir -p skills

# 3. Клонировать или скачать скилл
cd skills
git clone <URL репозитория>/agent-doctor.git
# Или распаковать ZIP

# 4. Готово!
# Агент автоматически подхватит скилл при следующем запуске
```

---

## Вариант 2: Ручная установка

```bash
# 1. Создать папку скилла
cd ~/path/to/your/workspace  # замените на свой путь
mkdir -p skills/agent-doctor

# 2. Скачать файлы
# Скопировать все .md файлы в skills/agent-doctor/

# Минимум нужен только SKILL.md или SKILL-public.md
# (переименовать SKILL-public.md в SKILL.md если используете публичную версию)

# 3. Сделать скрипт исполняемым (опционально)
chmod +x skills/agent-doctor/auto-diagnostic.sh
```

---

## Вариант 3: Быстрая установка одной командой

```bash
# Создать и скачать
mkdir -p ~/path/to/your/workspace/skills/agent-doctor && \
cd ~/path/to/your/workspace/skills/agent-doctor && \
curl -O <URL>/SKILL-public.md && \
mv SKILL-public.md SKILL.md && \
echo "✅ Установлено!"
```

---

## Проверка установки

```bash
# 1. Проверить что файл на месте
ls ~/path/to/your/workspace/skills/agent-doctor/SKILL.md

# 2. Запустить OpenClaw
openclaw gateway restart

# 3. Сказать агенту:
"самодиагностика"

# Если агент запустил проверку - всё работает!
```

---

## Первый запуск

После установки скажите агенту:

```
продиагностируй себя
```

Агент проверит:
- 🧠 Память (SQLite, WAL, embeddings)
- ⏰ Кроны (статус, ошибки)
- ⚙️ Конфиг (валидность, модели)
- 📁 Файлы (SOUL, USER, skills)
- 🔧 Gateway (статус, логи)
- 💾 Система (Node, Python, диск)
- 🛡️ Безопасность (bind, auth)

---

## Структура файлов

После установки должно быть:

```
skills/agent-doctor/
├── SKILL.md                  # Основной файл скилла (обязательно!)
├── SKILL-public.md           # Альтернативная публичная версия
├── README.md                 # Описание
├── INSTALL.md                # Эта инструкция
├── EXAMPLES.md               # Примеры использования
├── PROBLEMS_DATABASE.md      # База проблем и решений
├── CHANGELOG.md              # История версий
└── auto-diagnostic.sh        # Bash-скрипт (опционально)
```

**Минимум для работы:** только `SKILL.md`

Остальные файлы - справочные, можно удалить.

---

## Обновление

```bash
# Через Git
cd ~/path/to/your/workspace/skills/agent-doctor
git pull

# Вручную
# Заменить SKILL.md на новую версию

# После обновления
openclaw gateway restart
```

---

## Удаление

```bash
# Удалить папку скилла
rm -rf ~/path/to/your/workspace/skills/agent-doctor

# Перезапустить gateway
openclaw gateway restart
```

---

## Автоматическая диагностика (крон)

Хотите чтобы агент проверял себя автоматически каждое утро?

```bash
openclaw cron add daily-health-check \
  --schedule "0 8 * * *" \
  --model "anthropic/claude-sonnet-4-6" \
  --isolated \
  --payload '{
    "kind": "agentTurn",
    "message": "Запусти agent-doctor. Если найдешь критичные проблемы - отправь алерт. Если все ОК - молчи."
  }'
```

Теперь каждое утро в 8:00 агент проверит себя.

---

## Проблемы при установке

### "Агент не видит скилл"

**Причины:**
1. Неправильный путь к workspace
2. Файл называется не SKILL.md
3. Gateway не перезапущен

**Решение:**
```bash
# Проверить workspace
openclaw config get workspaceDir

# Переименовать файл
mv SKILL-public.md SKILL.md

# Перезапустить
openclaw gateway restart
```

### "Ошибка при чтении SKILL.md"

**Причина:** Неправильные права доступа

**Решение:**
```bash
chmod 644 ~/path/to/your/workspace/skills/agent-doctor/SKILL.md
```

### "Скилл работает, но bash-скрипт нет"

**Причина:** Не исполняемый

**Решение:**
```bash
chmod +x ~/path/to/your/workspace/skills/agent-doctor/auto-diagnostic.sh
```

---

## FAQ

**Q: Нужно ли перезапускать gateway после установки?**

A: Желательно, но не обязательно. Агент подхватит скилл при следующем сообщении.

**Q: Можно ли изменить SKILL.md под себя?**

A: Да! Это ваша копия, делайте что хотите. Добавляйте свои проверки, меняйте формат отчета.

**Q: Как часто обновлять скилл?**

A: Проверяйте CHANGELOG.md раз в месяц. Если появились новые проблемы в базе - стоит обновить.

**Q: Безопасно ли использовать bash-скрипт?**

A: Да, скрипт только читает данные. Ничего не меняет.

**Q: Работает ли на Windows?**

A: SKILL.md работает везде. Bash-скрипт - только Linux/macOS. На Windows используйте только SKILL.md через агента.

---

## Поддержка

Проблемы? Вопросы?

1. Прочитайте EXAMPLES.md - там 10 сценариев
2. Загляните в PROBLEMS_DATABASE.md - 28 решений
3. Откройте issue на GitHub

---

## Что дальше?

После установки:

1. ✅ Запустите первую диагностику: "продиагностируй себя"
2. ✅ Исправьте найденные проблемы
3. ✅ Добавьте автоматическую проверку (крон)
4. ✅ Запускайте после каждого обновления OpenClaw
5. ✅ Делитесь результатами в сообществе!

---

**Версия:** 1.0.0  
**Дата:** 2026-03-06  

🏥 Здоровый агент - продуктивный агент!
