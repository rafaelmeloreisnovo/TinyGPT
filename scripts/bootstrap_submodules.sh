#!/usr/bin/env bash
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] Este script deve ser executado dentro de um repositório Git." >&2
  exit 1
fi

echo "[INFO] Sincronizando configuração de submódulos..."
git submodule sync --recursive

echo "[INFO] Inicializando e atualizando submódulos recursivamente..."
git submodule update --init --recursive --jobs 8

echo "[INFO] Dependências via submódulo prontas."
