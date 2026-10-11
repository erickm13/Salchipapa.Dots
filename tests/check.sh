#!/usr/bin/env bash
# tests/check.sh — sintaxis y lint de todo el repo. Lo corre el CI (.github/workflows/ci.yml) y se
# puede correr a mano: bash tests/check.sh. Herramientas: shellcheck, fish, python3, node, jq,
# actionlint (las que falten se saltan con un aviso, salvo en el CI).
set -uo pipefail
cd "$(dirname "$0")/.."
fails=0
pass() { printf '  ✔ %s\n' "$1"; }
fail() { printf '  ✖ %s\n' "$1"; fails=$((fails + 1)); }
need() {
  command -v "$1" >/dev/null && return 0
  if [ "${CI:-}" = true ]; then fail "$1 no está instalado"; else printf '  ⚠ %s no está instalado: se salta\n' "$1"; fi
  return 1
}
files() { git ls-files -- "$@" | grep -v '^homebrew-tap/'; }

echo "bash (sintaxis):"
for f in $(files '*.sh'); do bash -n "$f" 2>/dev/null || fail "bash -n $f"; done
[ "$fails" -eq 0 ] && pass "$(files '*.sh' | wc -l) scripts"

echo "shellcheck:"
if need shellcheck; then
  # SC2034 (variables de color/opciones sin usar) y SC1090 (source dinamico de nvm) son conocidos
  if out="$(shellcheck -S warning -e SC2034,SC1090 $(files '*.sh') 2>&1)"; then
    pass "sin avisos"
  else
    printf '%s\n' "$out" | head -40
    fail "shellcheck"
  fi
fi

echo "fish (sintaxis):"
if need fish; then
  n=0
  for f in $(files '*.fish'); do fish -n "$f" 2>/dev/null || fail "fish -n $f"; n=$((n + 1)); done
  pass "$n archivos revisados"
fi

echo "python (compila):"
for f in $(files '*.py'); do python3 -m py_compile "$f" 2>/dev/null || fail "py_compile $f"; done
pass "$(files '*.py' | wc -l) scripts"

echo "javascript (sintaxis):"
if need node; then
  for f in $(files '*.js'); do node --check "$f" 2>/dev/null || fail "node --check $f"; done
  pass "$(files '*.js' | wc -l) archivos"
fi

echo "json:"
if need jq; then
  for f in $(files '*.json'); do jq empty "$f" 2>/dev/null || fail "json inválido: $f"; done
  pass "$(files '*.json' | wc -l) archivos"
fi

echo "workflows de GitHub Actions:"
if need actionlint; then
  if actionlint .github/workflows/*.yml && actionlint SalchipapaObsidian/github-actions/*.yml; then
    pass "actionlint"
  else
    fail "actionlint"
  fi
fi

echo
if [ "$fails" -eq 0 ]; then echo "✔ check: todo bien"; else echo "✖ check: $fails fallo(s)"; fi
[ "$fails" -eq 0 ]
