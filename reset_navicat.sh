#!/bin/bash
set -uo pipefail  # 启用严格错误处理

# ---------- 定义变量 ----------
APP_NAME="Navicat Premium"
APP_BUNDLE_ID="com.navicat.NavicatPremium"
APP_PATH="/Applications/Navicat Premium.app"
APP_INFO_PLIST="$APP_PATH/Contents/Info.plist"
APP_SUPPORT_DIR="$HOME/Library/Application Support/PremiumSoft CyberTech/Navicat CC/Navicat Premium"
PLIST_FILE="$HOME/Library/Preferences/$APP_BUNDLE_ID.plist"
BACKUP_DIR="$HOME/.navicat_reset_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ---------- 函数：记录日志 ----------
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# ---------- 函数：备份偏好设置文件 ----------
backup_plist() {
  if [[ -f "$PLIST_FILE" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp "$PLIST_FILE" "$BACKUP_DIR/navicat_plist_$TIMESTAMP.backup"
    log "已备份偏好设置文件到: $BACKUP_DIR/navicat_plist_$TIMESTAMP.backup"
  fi
}

# ---------- 函数：检查 Navicat 版本 ----------
check_navicat_version() {
  if [[ ! -f "$APP_INFO_PLIST" ]]; then
    log "错误: 无法找到 Navicat 的 Info.plist 文件 ($APP_INFO_PLIST)。请确认 $APP_NAME 是否安装。" >&2
    exit 1
  fi

  VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_INFO_PLIST" 2>/dev/null)
  if [[ $? -ne 0 || -z "$VERSION" ]]; then
    log "错误: 无法读取 Navicat 版本信息。" >&2
    exit 1
  fi

  log "检测到 $APP_NAME 版本: $VERSION"
  echo "$VERSION"
}

# ---------- 函数：根据版本调整清理逻辑 ----------
version_specific_cleanup() {
  local version="$1"
  local major_version
  major_version=$(echo "$version" | cut -d'.' -f1)

  log "根据版本 $version 执行清理..."

  if [[ "$major_version" -ge 16 ]]; then
    log "针对 Navicat 16 及以上版本执行清理..."
    # Navicat 16 可能有额外的试用数据存储位置
    find "$APP_SUPPORT_DIR" -maxdepth 2 -type f -name '.[0-9A-F][0-9A-F]*' 2>/dev/null | while IFS= read -r file; do
      filename=$(basename "$file")
      if echo "$filename" | grep -Eq '^\.([0-9A-F]{32})$'; then
        log "删除哈希文件: $filename"
        rm -f "$file" || {
          log "无法删除文件: $filename，请检查权限。" >&2
          exit 1
        }
      fi
    done
  else
    log "针对 Navicat 15 及以下版本执行清理..."
    # 标准清理逻辑
    find "$APP_SUPPORT_DIR" -maxdepth 1 -type f -name '.[0-9A-F][0-9A-F]*' 2>/dev/null | while IFS= read -r file; do
      filename=$(basename "$file")
      if echo "$filename" | grep -Eq '^\.([0-9A-F]{32})$'; then
        log "删除哈希文件: $filename"
        rm -f "$file" || {
          log "无法删除文件: $filename，请检查权限。" >&2
          exit 1
        }
      fi
    done
  fi
}

# ---------- 终止 Navicat 进程 ----------
log "正在终止 $APP_NAME 进程..."
if pgrep -f "$APP_NAME" >/dev/null; then
  if pkill -9 -f "$APP_NAME" 2>/dev/null; then
    log "已成功终止 $APP_NAME 进程。"
  else
    log "无法终止 $APP_NAME 进程，请检查权限。" >&2
    exit 1
  fi
else
  log "$APP_NAME 进程未运行，跳过终止。"
fi

# ---------- 检查 Navicat 版本 ----------
navicat_version=$(check_navicat_version)

# ---------- 清理应用支持目录的哈希文件 ----------
log "清理应用支持目录的哈希文件..."
if [[ -d "$APP_SUPPORT_DIR" ]]; then
  version_specific_cleanup "$navicat_version"
else
  log "应用支持目录不存在: $APP_SUPPORT_DIR"
fi

# ---------- 处理偏好设置文件 ----------
log "处理偏好设置文件..."
if [[ -f "$PLIST_FILE" ]]; then
  backup_plist
  keys_to_delete=$(/usr/libexec/PlistBuddy -c "Print" "$PLIST_FILE" 2>/dev/null | grep -Eoa "^\s{4}[0-9A-F]{32}" | tr -d ' ' | sort -u)
  if [[ -n "$keys_to_delete" ]]; then
    while IFS= read -r key; do
      log "删除密钥: $key"
      /usr/libexec/PlistBuddy -c "Delete :$key" "$PLIST_FILE" 2>/dev/null || {
        log "无法删除密钥: $key，请检查文件权限。" >&2
        exit 1
      }
    done <<< "$keys_to_delete"
  else
    log "未找到需要删除的32位哈希密钥。"
  fi
else
  log "偏好设置文件不存在: $PLIST_FILE"
fi

# ---------- 重启 Navicat ----------
log "正在启动 $APP_NAME..."
if open -a "$APP_NAME" 2>/dev/null; then
  log "$APP_NAME 已成功启动，试用期重置完成！"
else
  log "错误: 无法启动 $APP_NAME，请检查应用程序是否安装。" >&2
  exit 1
fi

exit 0