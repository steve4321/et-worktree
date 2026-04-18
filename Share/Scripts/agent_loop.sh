#!/bin/bash
#==============================================================================
# Claude Code 自动开发循环
# 在后台持续运行，监听任务队列，自动完成开发
#==============================================================================

set -e

AGENT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$AGENT_DIR/../.." && pwd)"
WORKTREE_NAME="${1:-}"

TASK_QUEUE_DIR="$AGENT_DIR/../var/queue/$WORKTREE_NAME"
LOG_FILE="$AGENT_DIR/../var/logs/$WORKTREE_NAME.log"
PID_FILE="$AGENT_DIR/../var/run/$WORKTREE_NAME.pid"

mkdir -p "$AGENT_DIR/../var/queue"
mkdir -p "$AGENT_DIR/../var/logs"
mkdir -p "$AGENT_DIR/../var/run"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# 检查是否已在运行
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        log "Agent $WORKTREE_NAME 已在运行 (PID: $OLD_PID)"
        exit 0
    fi
fi

# 保存 PID
echo $$ > "$PID_FILE"

log "启动 Agent: $WORKTREE_NAME"
log "工作目录: $PROJECT_ROOT/../et-worktree-$WORKTREE_NAME"

# 确保 worktree 存在
WT_PATH="$PROJECT_ROOT/../et-worktree-$WORKTREE_NAME"
if [ ! -d "$WT_PATH/.git" ]; then
    log "Error: Worktree $WORKTREE_NAME 不存在"
    exit 1
fi

cd "$WT_PATH"

# 主循环
while true; do
    # 检查任务队列
    if [ -d "$TASK_QUEUE_DIR" ] && [ "$(ls -A $TASK_QUEUE_DIR 2>/dev/null)" ]; then
        for task_file in "$TASK_QUEUE_DIR"/*.task; do
            if [ -f "$task_file" ]; then
                TASK=$(cat "$task_file")
                TASK_NAME=$(basename "$task_file" .task)
                log "开始执行任务: $TASK_NAME"

                # 执行任务
                echo "$TASK" | claude --no-input --dangerously-disable-sandbox --project "$WT_PATH" 2>&1 | tee -a "$LOG_FILE"

                # 任务完成，移到已完成目录
                mkdir -p "$TASK_QUEUE_DIR/done"
                mv "$task_file" "$TASK_QUEUE_DIR/done/"
                log "任务完成: $TASK_NAME"
            fi
        done
    fi

    # 每 60 秒检查一次（可通过信号中断）
    sleep 60 &
    wait $!
done
