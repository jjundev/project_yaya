#!/usr/bin/env bash

cd "$(dirname "$0")"

PORT=8420

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)
            PORT="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Start server in background
PY_EXE="$(dirname "$0")/.venv/bin/python3"
if [ ! -x "$PY_EXE" ]; then
    PY_EXE="python3"
fi
LOG_DIR="${TMPDIR:-/tmp}"
LOG_FILE="${LOG_DIR%/}/yaya-dashboard-$PORT.log"
nohup "$PY_EXE" -m harness --web --port "$PORT" >"$LOG_FILE" 2>&1 &
SERVER_PID=$!

cleanup() {
    kill "$SERVER_PID" 2>/dev/null
}
trap cleanup EXIT INT TERM

# Wait for server to be ready (max 30 seconds)
WAIT_COUNT=0
while [ $WAIT_COUNT -lt 30 ]; do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "Server process exited unexpectedly. Check for errors below."
        if [ -s "$LOG_FILE" ]; then
            tail -n 80 "$LOG_FILE"
        fi
        trap - EXIT INT TERM
        exit 1
    fi

    if curl -s "http://localhost:$PORT/" >/dev/null 2>&1; then
        trap - EXIT INT TERM   # server intentionally stays running
        echo "Opening dashboard at http://localhost:$PORT/"
        echo "Server log: $LOG_FILE"

        # Detect OS and open browser accordingly
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "http://localhost:$PORT/"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open "http://localhost:$PORT/" 2>/dev/null || echo "Could not open browser. Visit http://localhost:$PORT/ manually."
        elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
            start "http://localhost:$PORT/"
        else
            echo "Visit http://localhost:$PORT/ in your browser"
        fi
        exit 0
    fi

    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

trap - EXIT INT TERM
echo "Timeout waiting for server. Check if port $PORT is in use."
kill "$SERVER_PID" 2>/dev/null
exit 1
