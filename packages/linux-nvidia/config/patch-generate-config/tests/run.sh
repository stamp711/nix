set -euo pipefail
mkdir source build
export SRC="$PWD/source" BUILD_ROOT="$PWD/build"
export KERNEL_CONFIG="$PWD/answers" fixtureConfig="$PWD/resolved"
export DEBUG=0 AUTO_MODULES=0 PREFER_BUILTIN=0 ignoreConfigErrors=0
export ARCH=x86 CROSS_COMPILE= MAKE_FLAGS=

check() {
    local name="$1" expected="$2" answers="$3" resolved="$4" diagnostic="${5:-}"
    printf '%s\n' "$answers" > "$KERNEL_CONFIG"
    printf '%s\n' "$resolved" > "$fixtureConfig"
    local status=0
    perl -w "$generateConfig" > "$name.log" 2>&1 || status=$?
    if { [ "$expected" = pass ] && [ "$status" -ne 0 ]; } ||
       { [ "$expected" = fail ] && [ "$status" -eq 0 ]; }; then
        cat "$name.log"
        echo "Unexpected result: $name (exit $status)" >&2
        exit 1
    fi
    if [ -n "$diagnostic" ] && ! grep -Fq "$diagnostic" "$name.log"; then
        cat "$name.log"
        echo "Missing diagnostic: $name" >&2
        exit 1
    fi
}

check absent-disabled pass 'DISABLED n' ''
check explicit-disabled pass 'DISABLED n' '# CONFIG_DISABLED is not set'
check unexpectedly-enabled fail 'DISABLED n' 'CONFIG_DISABLED=y' 'option not set correctly: DISABLED'
check unexpectedly-module fail 'DISABLED n' 'CONFIG_DISABLED=m' 'option not set correctly: DISABLED'
check absent-enabled fail 'ENABLED y' '' 'unused option: ENABLED'
check absent-module fail 'ENABLED m' '' 'unused option: ENABLED'
check disabled-enabled fail 'ENABLED y' '# CONFIG_ENABLED is not set' 'option not set correctly: ENABLED'
check matching-module pass 'ENABLED m' 'CONFIG_ENABLED=m'
check zero-mismatch fail 'NUMBER 1' 'CONFIG_NUMBER=0' 'option not set correctly: NUMBER'
check empty-mismatch fail 'TEXT expected' 'CONFIG_TEXT=""' 'option not set correctly: TEXT'
check matching-zero pass 'NUMBER 0' 'CONFIG_NUMBER=0'
check matching-empty pass 'TEXT' 'CONFIG_TEXT=""'

echo 'All config checker regression cases passed'
