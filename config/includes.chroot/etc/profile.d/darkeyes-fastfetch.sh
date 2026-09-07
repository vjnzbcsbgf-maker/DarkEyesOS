# DarkEyesOS: show the branded fastfetch banner on interactive login shells.
case "$-" in
    *i*)
        if [ -z "${DARKEYES_FETCH_SHOWN:-}" ] && command -v fastfetch >/dev/null 2>&1; then
            DARKEYES_FETCH_SHOWN=1
            export DARKEYES_FETCH_SHOWN
            /usr/local/bin/darkeyes-fetch 2>/dev/null || true
        fi
        ;;
esac
