#!/bin/bash

# 配置环境变量
export PORT=${PORT:-"8080"}
export VNC_PASSWORD=${VNC_PASSWORD:-"123456"}
export RESOLUTION=${RESOLUTION:-"1280x720"}
export LANG=${LANG:-"zh_CN.UTF-8"}
export DISPLAY=:0
export HOME=/home/vncuser
export USER=vncuser
export TMPDIR=/home/vncuser/tmp

# 设置中文环境
export LC_ALL=$LANG
export LANGUAGE=zh_CN:zh:en_US:en
export LC_CTYPE=zh_CN.UTF-8
export LC_NUMERIC=zh_CN.UTF-8
export LC_TIME=zh_CN.UTF-8
export LC_COLLATE=zh_CN.UTF-8
export LC_MONETARY=zh_CN.UTF-8
export LC_MESSAGES=zh_CN.UTF-8
export LC_PAPER=zh_CN.UTF-8
export LC_NAME=zh_CN.UTF-8
export LC_ADDRESS=zh_CN.UTF-8
export LC_TELEPHONE=zh_CN.UTF-8
export LC_MEASUREMENT=zh_CN.UTF-8
export LC_IDENTIFICATION=zh_CN.UTF-8
export DBUS_SESSION_BUS_ADDRESS=unix:path=/var/run/dbus/system_bus_socket

# 创建必要目录
mkdir -p /home/vncuser/.vnc
mkdir -p /home/vncuser/.fluxbox
mkdir -p /home/vncuser/tmp
mkdir -p /tmp/.X11-unix
mkdir -p /home/vncuser/.mozilla/firefox/default
mkdir -p /home/vncuser/.mozilla/firefox/Crash\ Reports
mkdir -p /var/run/dbus

# 设置权限
chmod 700 /home/vncuser/.vnc
chmod 1777 /tmp/.X11-unix
chmod 700 /home/vncuser/tmp
chmod 755 /var/run/dbus
chown -R vncuser:vncuser /home/vncuser

# 设置VNC密码
echo "设置VNC密码..."
echo "$VNC_PASSWORD" | x11vnc -storepasswd - > /home/vncuser/.vnc/passwd
chmod 600 /home/vncuser/.vnc/passwd

# 清理旧的锁文件
echo "清理旧的X11锁文件..."
rm -f /tmp/.X0-lock /tmp/.X11-unix/X0 2>/dev/null || true
rm -f /home/vncuser/.Xauthority 2>/dev/null || true

# 解析分辨率
IFS='x' read -ra RES <<< "$RESOLUTION"
VNC_WIDTH="${RES[0]}"
VNC_HEIGHT="${RES[1]}"
VNC_DEPTH="24"

echo "分辨率: ${VNC_WIDTH}x${VNC_HEIGHT}"

# 显示当前语言环境设置
echo "当前语言环境:"
echo "LANG=$LANG"
echo "LC_ALL=$LC_ALL"
echo "LANGUAGE=$LANGUAGE"

# 创建Firefox配置
cat > /home/vncuser/.mozilla/firefox/profiles.ini << EOF
[General]
StartWithLastProfile=1

[Profile0]
Name=default
IsRelative=1
Path=default
Default=1
EOF

# 创建Fluxbox配置
cat > /home/vncuser/.fluxbox/init << EOF
session.screen0.workspaces: 1
session.screen0.workspacewarping: false
session.screen0.toolbar.visible: false
session.screen0.fullMaximization: true
session.screen0.maxDisableMove: false
session.screen0.maxDisableResize: false
session.screen0.defaultDeco: NONE
EOF

# 创建Fluxbox启动脚本，确保中文环境
cat > /home/vncuser/.fluxbox/startup << 'EOF'
#!/bin/bash
# Fluxbox启动脚本
# 设置完整中文环境
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh:en_US:en
export LC_ALL=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
export DBUS_SESSION_BUS_ADDRESS=unix:path=/var/run/dbus/system_bus_socket

# 等待X服务器完全启动
sleep 3

# 启动Firefox前检查语言环境
echo "Firefox启动环境: LANG=$LANG, LC_ALL=$LC_ALL"

# 启动Firefox（使用会话恢复模式）
firefox --width=1280 --height=720 --new-instance --no-remote &
EOF

chmod +x /home/vncuser/.fluxbox/startup
chown -R vncuser:vncuser /home/vncuser/.fluxbox
chown -R vncuser:vncuser /home/vncuser/.mozilla

echo "🚀 启动Xvfb显示服务器..."
# 启动Xvfb（显示服务器）
Xvfb :0 -screen 0 ${VNC_WIDTH}x${VNC_HEIGHT}x${VNC_DEPTH} -ac +extension RANDR -nolisten tcp -noreset &
XVFB_PID=$!

# 等待Xvfb启动
sleep 3

# 检查Xvfb是否成功启动
if ! kill -0 $XVFB_PID 2>/dev/null; then
    echo "❌ Xvfb启动失败"
    exit 1
fi

echo "✅ Xvfb启动成功 (PID: $XVFB_PID)"

echo "🚀 启动Fluxbox窗口管理器..."
# 启动Fluxbox
fluxbox -display :0 &
FLUXBOX_PID=$!
sleep 3

echo "🚀 启动x11vnc服务器..."
# 启动x11vnc（使用默认端口5900，但只在容器内部访问）
x11vnc -display :0 -forever -shared -passwd "$VNC_PASSWORD" -rfbport 5900 -localhost -noxdamage -xrandr &
X11VNC_PID=$!
sleep 2

echo "🚀 启动noVNC网页客户端..."
# 启动noVNC（作为反向代理，将外部8080端口请求转发到内部5900端口）
websockify --web /usr/share/novnc $PORT localhost:5900 &
NOVNC_PID=$!
sleep 2

echo "等待Firefox启动..."
# 给Fluxbox startup脚本时间启动Firefox
sleep 10

echo "==========================================="
echo "✅ 所有服务启动完成！"
echo "📺 VNC 分辨率: ${RESOLUTION}"
echo "🔑 VNC 密码: ${VNC_PASSWORD}"
echo "🌐 访问地址: http://localhost:${PORT}"
echo "🏠 默认主页: https://nav.eooce.com"
echo "🔤 语言设置: 中文 (简体)"
echo "🔄 崩溃恢复: 已启用"
echo "==========================================="

# 检查所有进程是否在运行
echo "进程状态检查:"
if kill -0 $XVFB_PID 2>/dev/null; then echo "✅ Xvfb 运行中"; else echo "❌ Xvfb 已停止"; fi
if kill -0 $FLUXBOX_PID 2>/dev/null; then echo "✅ Fluxbox 运行中"; else echo "❌ Fluxbox 已停止"; fi
if kill -0 $X11VNC_PID 2>/dev/null; then echo "✅ x11vnc 运行中"; else echo "❌ x11vnc 已停止"; fi
if kill -0 $NOVNC_PID 2>/dev/null; then echo "✅ noVNC 运行中"; else echo "❌ noVNC 已停止"; fi

# Firefox进程监控变量
FIREFOX_RESTART_COUNT=0
MAX_RESTARTS=10
LAST_RESTART_TIME=0
RESTART_COOLDOWN=10  # 重启冷却时间(秒)

# 检查Firefox进程的初始启动
check_firefox_initial_start() {
    local max_wait=30
    local wait_count=0
    
    while [ $wait_count -lt $max_wait ]; do
        FIREFOX_PID=$(pgrep -f "firefox.*--width" || true)
        if [ -n "$FIREFOX_PID" ]; then
            echo "✅ Firefox 初始启动成功 (PID: $FIREFOX_PID)"
            return 0
        fi
        sleep 1
        ((wait_count++))
    done
    
    echo "⚠️  Firefox 初始启动超时，尝试手动启动..."
    start_firefox
}

# 启动Firefox函数
start_firefox() {
    local current_time=$(date +%s)
    
    # 检查冷却时间
    if [ $((current_time - LAST_RESTART_TIME)) -lt $RESTART_COOLDOWN ]; then
        echo "⚠️  重启过于频繁，等待冷却..."
        sleep $RESTART_COOLDOWN
    fi
    
    # 检查重启次数
    if [ $FIREFOX_RESTART_COUNT -ge $MAX_RESTARTS ]; then
        echo "❌ Firefox 重启次数过多 ($FIREFOX_RESTART_COUNT 次)，停止自动重启"
        return 1
    fi
    
    echo "🔄 启动Firefox (重启次数: $((FIREFOX_RESTART_COUNT + 1))/$MAX_RESTARTS)"
    
    # 使用完整中文环境启动Firefox
    export LANG=zh_CN.UTF-8
    export LANGUAGE=zh_CN:zh:en_US:en
    export LC_ALL=zh_CN.UTF-8
    
    # 启动Firefox（使用会话恢复）
    firefox --display=:0 --width=${VNC_WIDTH} --height=${VNC_HEIGHT} --new-instance --no-remote > /home/vncuser/firefox.log 2>&1 &
    
    sleep 5
    
    FIREFOX_PID=$(pgrep -f "firefox.*--width" || true)
    if [ -n "$FIREFOX_PID" ]; then
        echo "✅ Firefox 启动成功 (PID: $FIREFOX_PID)"
        ((FIREFOX_RESTART_COUNT++))
        LAST_RESTART_TIME=$(date +%s)
        return 0
    else
        echo "❌ Firefox 启动失败"
        if [ -f /home/vncuser/firefox.log ]; then
            echo "Firefox 错误日志:"
            tail -20 /home/vncuser/firefox.log
        fi
        return 1
    fi
}

# 初始检查Firefox
check_firefox_initial_start

# 主进程保持运行
echo "🔄 进入主监控循环..."
while true; do
    # 检查关键进程是否存活
    if ! kill -0 $XVFB_PID 2>/dev/null; then
        echo "❌ Xvfb 进程已停止，退出容器"
        exit 1
    fi
    
    if ! kill -0 $X11VNC_PID 2>/dev/null; then
        echo "❌ x11vnc 进程已停止，退出容器"
        exit 1
    fi
    
    # 检查Firefox进程
    FIREFOX_PID=$(pgrep -f "firefox.*--width" || true)
    if [ -z "$FIREFOX_PID" ]; then
        echo "⚠️  Firefox 已停止，尝试重新启动..."
        
        # 检查是否有崩溃报告
        if [ -d "/home/vncuser/.mozilla/firefox/Crash Reports" ]; then
            CRASH_COUNT=$(find "/home/vncuser/.mozilla/firefox/Crash Reports" -name "*.dmp" 2>/dev/null | wc -l)
            if [ $CRASH_COUNT -gt 0 ]; then
                echo "📊 检测到 $CRASH_COUNT 个崩溃报告，Firefox将尝试恢复会话"
            fi
        fi
        
        # 清理可能的僵尸进程
        pkill -f firefox || true
        sleep 2
        
        # 重启Firefox
        if start_firefox; then
            echo "✅ Firefox 重启成功，将恢复之前的会话"
        else
            echo "❌ Firefox 重启失败"
        fi
    else
        # Firefox正在运行，检查是否无响应
        if ! kill -0 $FIREFOX_PID 2>/dev/null; then
            echo "⚠️  Firefox 进程存在但无响应，强制重启..."
            kill -9 $FIREFOX_PID 2>/dev/null || true
            sleep 2
            start_firefox
        fi
    fi
    
    # 每30秒检查一次（比之前更频繁）
    sleep 30
    
    # 每5分钟重置重启计数器（防止长时间运行后达到限制）
    if [ $(( $(date +%s) - LAST_RESTART_TIME )) -gt 300 ]; then
        FIREFOX_RESTART_COUNT=0
        echo "🔄 重置Firefox重启计数器"
    fi
done
