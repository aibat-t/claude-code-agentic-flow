#!/usr/bin/env bash
# java-flow guard: PreToolUse для Bash и Edit|Write|MultiEdit.
# Блокирует (exit 2): push в main/master, force push, изменение существующих миграций.

set -f
input="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  echo "java-flow guard: jq не установлен — проверки пропущены" >&2
  exit 0
fi

block() {
  echo "java-flow guard: $1" >&2
  exit 2
}

tool="$(jq -r '.tool_name // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"

check_push() {
  local seg="$1"
  # аргументы после "push"
  local args="${seg#*push}"
  local tok positional=()
  for tok in $args; do
    case "$tok" in
      --force|--force=*|--force-with-lease|--force-with-lease=*|--force-if-includes)
        block "force push запрещён: $seg" ;;
      --*) ;;
      -*f*) block "force push запрещён: $seg" ;;
      -*) ;;
      +*) block "force push (+refspec) запрещён: $seg" ;;
      *) positional+=("$tok") ;;
    esac
  done
  local ref
  for ref in "${positional[@]:1}"; do
    ref="${ref##*:}"
    ref="${ref#refs/heads/}"
    case "$ref" in
      main|master) block "push в $ref запрещён. Создай feature/fix-ветку." ;;
    esac
  done
  # git push без refspec на main/master
  if [ "${#positional[@]}" -le 1 ]; then
    local branch
    branch="$(git -C "${cwd:-.}" branch --show-current 2>/dev/null)"
    case "$branch" in
      main|master) block "текущая ветка $branch — push запрещён. Создай feature/fix-ветку." ;;
    esac
  fi
}

case "$tool" in
  Bash)
    cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
    # разбиваем цепочку команд на сегменты
    while IFS= read -r seg; do
      if [[ "$seg" =~ ^[[:space:]]*git([[:space:]]+-[Cc][[:space:]]+[^[:space:]]+)*[[:space:]]+push([[:space:]]|$) ]]; then
        check_push "$seg"
      fi
    done < <(sed -E 's/(&&|\|\||;|\|)/\n/g' <<<"$cmd")
    ;;
  Edit|Write|MultiEdit)
    path="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
    norm="${path//\\//}"
    if [[ "$norm" == */db/migration/* || "$norm" == */db/changelog/* ]] && [ -e "$path" ]; then
      block "изменение существующей миграции запрещено: $path. Создай новую миграцию."
    fi
    ;;
esac

exit 0
