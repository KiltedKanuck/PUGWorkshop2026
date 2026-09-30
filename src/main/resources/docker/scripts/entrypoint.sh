#!/bin/sh
# ----- k6 Client Entrypoint Script -----
# ----- Company: Progress Software
# ----- Author: Dustin Grau - dugrau@progress.com
# ----- Date: 2026-05-26
# -----
# ----- Purpose: Refresh configs/docs volumes from baked samples without deleting user custom files
# -----
set -e

# ----- Refresh mounted /configs/ from distributed configs on each run.
# ----- Behavior:
# ----- 1) All dist files are unconditionally copied on every run.
# ----- 2) User-only files in configs (not in configs.dist) are left untouched.
# ----- NOTE: Users should keep custom copies outside configs.dist to avoid overwrites.
if [ -d "/opt/k6/tests/configs.dist" ]; then
    echo "Refreshing with distributed configurations..."

    mkdir -p /opt/k6/tests/configs

    cd /opt/k6/tests/configs.dist
    find . -type d -exec mkdir -p /opt/k6/tests/configs/{} \;

    find . -type f | while IFS= read -r relative_path; do
        src_file="/opt/k6/tests/configs.dist/${relative_path}"
        dst_file="/opt/k6/tests/configs/${relative_path}"

        cp "${src_file}" "${dst_file}" 2>/dev/null || true
    done

    echo "Configs refresh complete."
fi

# ----- Refresh mounted /docs/from distributed docs on each run.
# ----- Behavior:
# ----- 1) All dist files are unconditionally copied on every run.
# ----- 2) User-only files in docs (not in docs.dist) are left untouched.
# ----- NOTE: Users should keep custom copies outside docs.dist to avoid overwrites.
if [ -d "/opt/k6/tests/docs.dist" ]; then
    echo "Refreshing with distributed documentation..."

    mkdir -p /opt/k6/tests/docs

    cd /opt/k6/tests/docs.dist
    find . -type d -exec mkdir -p /opt/k6/tests/docs/{} \;

    find . -type f | while IFS= read -r relative_path; do
        src_file="/opt/k6/tests/docs.dist/${relative_path}"
        dst_file="/opt/k6/tests/docs/${relative_path}"

        cp "${src_file}" "${dst_file}" 2>/dev/null || true
    done

    echo "Docs refresh complete."
fi

# ----- Ensure command starts from expected tests working directory.
cd /opt/k6/tests

# ----- Execute the command passed to the container
# ----- This preserves the default k6 entrypoint behavior
exec "$@"
