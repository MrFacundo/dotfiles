#!/usr/bin/env bash

languages=("pt" "en" "fr")
selected=0

trap 'tput cnorm; exit' EXIT INT TERM

tput civis

draw_menu() {
  clear
  echo
  for i in "${!languages[@]}"; do
    if [[ $i -eq $selected ]]; then
      echo "❯ ${languages[$i]}"
    else
      echo "  ${languages[$i]}"
    fi
  done
}

while true; do
  draw_menu
  IFS= read -rsn1 key

  case "$key" in
  "")
    clear
    echo "Selected: ${languages[$selected]}"
    aichat -r "${languages[$selected]}" -s "${languages[$selected]}"
    break
    ;;
  j)
    ((selected++))
    ((selected >= ${#languages[@]})) && selected=0
    ;;
  k)
    ((selected--))
    ((selected < 0)) && selected=$((${#languages[@]} - 1))
    ;;
  $'\x1b')
    IFS= read -rsn1 key2
    IFS= read -rsn1 key3
    [[ $key2 == "[" ]] || continue
    case "$key3" in
    A)
      ((selected--))
      ((selected < 0)) && selected=$((${#languages[@]} - 1))
      ;;
    B)
      ((selected++))
      ((selected >= ${#languages[@]})) && selected=0
      ;;
    esac
    ;;
  esac
done
