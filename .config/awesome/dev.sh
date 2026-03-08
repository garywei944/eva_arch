#!/usr/bin/env bash
set -euxo pipefail

DISPLAY_NUM=":1"
SCREEN="1600x900"
CONFIG="${HOME}/.config/awesome/rc.lua"

echo "[dev] killing old Xephyr..."
pkill -f "Xephyr ${DISPLAY_NUM}" 2>/dev/null || true

echo "[dev] starting Xephyr..."
Xephyr ${DISPLAY_NUM} -br -ac -noreset -screen ${SCREEN} &
XEPHYR_PID=$!

# wait for X server

sleep 0.5

echo "[dev] launching AwesomeWM..."
DISPLAY=${DISPLAY_NUM} awesome -c "${CONFIG}" 2>/tmp/awesome-dev.log

echo "[dev] awesome exited"

wait ${XEPHYR_PID}
