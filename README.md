# claude-code-agentic-flow (ccaf)

Claude Code плагин для разработки на Java/Spring: от задачи до запушенной ветки по утверждённому плану.

```
задача → анализ → план → [апрув] → код → unit-тесты → билд + тесты → commit + push
```

## Установка

Из GitHub:
```
/plugin marketplace add aibat-t/claude-code-agentic-flow
/plugin install ccaf@claude-code-agentic-flow
```

Локально (для разработки плагина):
```
/plugin marketplace add ./claude-code-agentic-flow
/plugin install ccaf@claude-code-agentic-flow
```

Требуется `jq` для hook-защиты (`winget install jqlang.jq` / `brew install jq` / `apt install jq`). Без него защита пропускается с предупреждением.

## Первый запуск в проекте

```
/ccaf:setup
```
Добавляет в `CLAUDE.md` проекта раздел `## ccaf`: команды билда и тестов, модули, миграции, эталонные классы. Проверьте и поправьте его — от него зависит качество всего флоу.

## Команды

| Команда | Что делает | Когда |
|---|---|---|
| `/ccaf:setup` | Создаёт/дополняет `CLAUDE.md` проекта | Один раз на проект, после крупных изменений структуры |
| `/ccaf:task <задача>` | Весь флоу: план → апрув → код → тесты → проверка → commit + push | Обычная задача или баг целиком |
| `/ccaf:plan <задача> [--artifact\|--no-artifact]` | Анализ + план в `docs/plans/<ID>.md`, стоп. План масштаба L (или с `--artifact`) публикуется ещё и как Artifact | Нужен только план или хотите контролировать каждый этап |
| `/ccaf:implement [план]` | Код + тесты + проверка (до 3 попыток) | План утверждён |
| `/ccaf:verify [модуль\|Test#method\|full]` | Билд и тесты, статус PASS/FAIL | Проверить текущее состояние |
| `/ccaf:review [--staged\|путь\|PR#]` | Код-ревью: находки CRITICAL/HIGH/MEDIUM/LOW с исправлениями | Перед отправкой или для чужого PR |
| `/ccaf:ship` | Ветка, коммит, push | Всё зелёное, пора отправлять |

Правки плана: просто напишите комментарии после `/ccaf:plan` — план обновится в том же файле. Апрув — «ок»/«апрув».

## Агенты и skills

- **Агенты** (`analyst`, `verifier`, `reviewer`) — работают в изолированном контексте: читают много кода или логов билда и возвращают короткую сводку, не засоряя основную сессию.
- **Skills** (`planning`, `implementing`, `testing`, `reviewing`, `shipping`) — правила этапов, выполняются в основной сессии, где виден весь контекст задачи.
- Конвенции конкретного проекта — не в плагине, а в `CLAUDE.md` проекта и в соседнем коде.

## Как тюнить

| Файл | За что отвечает |
|---|---|
| `skills/planning/SKILL.md` | Как строится план, вопросы, самопроверка |
| `skills/planning/plan-template.md` | Формат файла плана |
| `skills/implementing/SKILL.md` | Правила написания кода |
| `skills/testing/SKILL.md` | Правила тестов |
| `skills/reviewing/SKILL.md` | Правила ревью, уровни, формат находок |
| `skills/shipping/SKILL.md` | Ветки, коммиты, push |
| `agents/analyst.md` | Анализ кода и бага, формат сводки |
| `agents/verifier.md` | Команды билда, чтение отчётов, формат статуса |
| `agents/reviewer.md` | Порядок ревью, разрешённые команды |
| `commands/*.md` | Порядок этапов в командах |
| `hooks/guard.sh` | Запреты: push в main/master, force push, правка миграций |

После правок:
1. Поднять `version` в `.claude-plugin/plugin.json`.
2. Закоммитить и запушить.
3. В проекте: `/plugin marketplace update claude-code-agentic-flow`, затем перезапустить сессию.

## Плагин для всей команды

В `.claude/settings.json` проекта:
```json
{
  "extraKnownMarketplaces": {
    "claude-code-agentic-flow": {
      "source": { "source": "github", "repo": "aibat-t/claude-code-agentic-flow" }
    }
  },
  "enabledPlugins": {
    "ccaf@claude-code-agentic-flow": true
  }
}
```
При открытии проекта Claude Code предложит установить маркетплейс и плагин.
