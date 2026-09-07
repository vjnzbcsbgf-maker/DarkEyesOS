#!/usr/bin/env bash
# lint.sh — sanity-check the build system without building a full image.
# Runs shellcheck on shell tools/hooks (if available), python compile check on
# the Control Center, and validates a few config files.
set -uo pipefail
cd "$(dirname "$0")/.."

fail=0
note() { printf '  %s\n' "$*"; }

echo "== Shell syntax (interpreter -n) =="
while IFS= read -r f; do
    shebang="$(head -n1 "$f")"
    case "$shebang" in
        *bash*) chk=bash ;;
        *sh*)   chk=sh ;;
        *)      continue ;;
    esac
    if "$chk" -n "$f" 2>/tmp/lint.$$; then note "ok   ($chk) $f"; else
        note "FAIL ($chk) $f"; cat /tmp/lint.$$; fail=1; fi
done < <(find config scripts build.sh -type f \( -name '*.sh' -o -perm -u+x \) 2>/dev/null \
         | grep -v __pycache__ | sort -u)
rm -f /tmp/lint.$$

echo "== shellcheck (if installed) =="
if command -v shellcheck >/dev/null 2>&1; then
    find config/hooks config/includes.chroot/usr/local/bin scripts build.sh \
        -type f | while read -r f; do
        head -n1 "$f" | grep -qE '^#!.*(sh|bash)' && shellcheck -S warning "$f" || true
    done
else
    note "shellcheck not installed — skipped (install: apt-get install shellcheck)"
fi

echo "== Python compile (Control Center) =="
if command -v python3 >/dev/null 2>&1; then
    if PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile \
        config/includes.chroot/usr/local/bin/darkeyes-control-center; then
        note "ok   darkeyes-control-center compiles"
    else note "FAIL darkeyes-control-center"; fail=1; fi
else note "python3 not installed — skipped"; fi

echo "== Config sanity =="
for want in \
    auto/config \
    config/includes.chroot/etc/tor/torrc \
    config/includes.chroot/etc/nftables.conf \
    config/includes.chroot/etc/sysctl.d/99-darkeyes-hardening.conf ; do
    [ -f "$want" ] && note "ok   $want" || { note "MISSING $want"; fail=1; }
done

# Every hook must be executable, or live-build silently ignores it.
echo "== Hook executability =="
for h in config/hooks/live/*.hook.chroot config/includes.chroot/usr/local/bin/*; do
    case "$h" in *__pycache__*) continue ;; esac
    [ -x "$h" ] && note "ok   +x $h" || { note "NOT EXECUTABLE $h"; fail=1; }
done

echo
if [ "$fail" = 0 ]; then echo "LINT PASSED"; else echo "LINT FAILED"; fi
exit "$fail"
