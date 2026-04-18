#!/bin/bash
#==============================================================================
# ET Worktree 自动化并行开发脚本
# 用法: ./auto_dev.sh [worktree_name] [task_file]
#   worktree_name: combat | equipment | collection | all (默认 all)
#   task_file: 任务描述文件路径
#==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

WORKTREE_NAME="${1:-all}"
TASK_FILE="${2:-}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 工作树列表
WORKTREES=("combat" "equipment" "collection")

# 检查 worktree 是否存在
check_worktree() {
    local wt="$1"
    if [ ! -d "$PROJECT_ROOT/../et-worktree-$wt" ]; then
        log_error "Worktree et-worktree-$wt 不存在"
        return 1
    fi
    return 0
}

# 为指定 worktree 运行 Claude Code
run_claude_for_worktree() {
    local wt="$1"
    local task="$2"
    local wt_path="$PROJECT_ROOT/../et-worktree-$wt"

    log_info "启动 worktree-$wt 开发..."

    # 检查是否有待完成的任务
    if [ -z "$task" ]; then
        log_info "worktree-$wt 无待处理任务，跳过"
        return 0
    fi

    # 在 worktree 目录运行 Claude Code
    cd "$wt_path"

    # 使用 --no-input 模式运行 Claude Code（无交互）
    # 添加任务描述
    echo "$task" | claude --no-input --dangerously-disable-sandbox 2>&1 || {
        log_warn "worktree-$wt Claude Code 执行完成（可能非零退出）"
    }

    log_success "worktree-$wt 开发轮次完成"
}

# 编译指定 worktree
build_worktree() {
    local wt="$1"
    local wt_path="$PROJECT_ROOT/../et-worktree-$wt"

    log_info "编译 worktree-$wt ..."

    cd "$wt_path"

    # 编译 Unity Model/Hotfix
    dotnet build Unity/Assets/Scripts/Model/Model.csproj -c Release --nologo -v q 2>&1 | tail -5

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        log_success "worktree-$wt 编译成功"
        return 0
    else
        log_error "worktree-$wt 编译失败"
        return 1
    fi
}

# 编译所有 worktree
build_all() {
    log_info "开始编译所有 worktree ..."

    local failed=0
    for wt in "${WORKTREES[@]}"; do
        if ! check_worktree "$wt"; then
            continue
        fi
        if ! build_worktree "$wt"; then
            failed=$((failed + 1))
        fi
    done

    if [ $failed -eq 0 ]; then
        log_success "所有 worktree 编译成功"
        return 0
    else
        log_error "$failed 个 worktree 编译失败"
        return 1
    fi
}

# 显示使用帮助
show_help() {
    echo "ET Worktree 自动化并行开发脚本"
    echo ""
    echo "用法:"
    echo "  $0 <command> [options]"
    echo ""
    echo "命令:"
    echo "  build [wt]     编译指定 worktree 或全部"
    echo "  dev <wt> <task> 在指定 worktree 运行 Claude Code 开发"
    echo "  all <task>     在所有 worktree 并行运行开发"
    echo "  status         显示所有 worktree 状态"
    echo "  help           显示此帮助"
    echo ""
    echo "示例:"
    echo "  $0 build                # 编译所有 worktree"
    echo "  $0 build combat        # 只编译 combat"
    echo "  $0 dev combat '实现技能系统'"  # 在 combat 开发"
    echo "  $0 all '实现装备系统'"  # 在所有 worktree 开发"
}

# 显示 worktree 状态
show_status() {
    echo "=========================================="
    echo "Worktree 状态"
    echo "=========================================="

    for wt in "${WORKTREES[@]}"; do
        local wt_path="$PROJECT_ROOT/../et-worktree-$wt"
        if [ -d "$wt_path/.git" ]; then
            cd "$wt_path"
            local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
            local status=$(git status -s --porcelain 2>/dev/null | wc -l | tr -d ' ')
            echo -e "${GREEN}✓${NC} et-worktree-$wt"
            echo "  Branch: $branch"
            echo "  Changed files: $status"
        else
            echo -e "${RED}✗${NC} et-worktree-$wt (不存在)"
        fi
    done
    echo "=========================================="
}

# 主逻辑
case "$WORKTREE_NAME" in
    "build")
        if [ -z "$2" ]; then
            build_all
        else
            WT="$2"
            if check_worktree "$WT"; then
                build_worktree "$WT"
            fi
        fi
        ;;
    "dev")
        WT="$2"
        TASK="$3"
        if [ -z "$WT" ] || [ -z "$TASK" ]; then
            log_error "dev 命令需要 worktree 名称和任务描述"
            show_help
            exit 1
        fi
        if check_worktree "$WT"; then
            run_claude_for_worktree "$WT" "$TASK"
        fi
        ;;
    "all")
        TASK="$2"
        if [ -z "$TASK" ]; then
            log_error "all 命令需要任务描述"
            show_help
            exit 1
        fi
        for wt in "${WORKTREES[@]}"; do
            if check_worktree "$wt"; then
                run_claude_for_worktree "$wt" "$TASK" &
            fi
        done
        wait
        log_success "所有 worktree 开发轮次完成"
        ;;
    "status")
        show_status
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        log_error "未知命令: $WORKTREE_NAME"
        show_help
        exit 1
        ;;
esac
