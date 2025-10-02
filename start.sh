#!/bin/bash

# 配置变量（使用环境变量或默认值）
export PORT=${PORT:-"8080"}
export VNC_PASSWORD=${VNC_PASSWORD:-"123456"}
export RESOLUTION=${RESOLUTION:-"1366x768"}
export LANG=${LANG:-"zh_CN.UTF-8"}
export LANGUAGE=${LANGUAGE:-"zh_CN:zh"}
export LC_ALL=${LC_ALL:-"zh_CN.UTF-8"}
export DISPLAY=:0
export HOME=/home/vncuser
export USER=vncuser
export TMPDIR=/home/vncuser/tmp

# 设置默认主页
export HOME_PAGE=${HOME_PAGE:-"https://nav.eooce.com"}

# 创建必要目录
mkdir -p /home/vncuser/.vnc
mkdir -p /home/vncuser/.fluxbox
mkdir -p /home/vncuser/tmp
mkdir -p /tmp/.X11-unix
mkdir -p /home/vncuser/.mozilla/firefox

# 如果Firefox配置目录为空，则复制默认配置
if [ ! -f /home/vncuser/.mozilla/firefox/profiles.ini ]; then
    echo "初始化Firefox配置..."
    cp /home/vncuser/firefox-prefs.js /home/vncuser/.mozilla/firefox/prefs.js
fi

# 设置权限
chmod 700 /home/vncuser/.vnc
chmod 1777 /tmp/.X11-unix
chmod 700 /home/vncuser/tmp
chown -R vncuser:vncuser /home/vncuser

# 设置VNC密码
echo "设置VNC密码..."
echo "$VNC_PASSWORD" | x11vnc -storepasswd - > /home/vncuser/.vnc/passwd
chmod 600 /home/vncuser/.vnc/passwd

# 清理旧的锁文件
echo "清理旧的X11锁文件..."
rm -f /tmp/.X0-lock /tmp/.X11-unix/X0 2>/dev/null || true

# 解析分辨率
IFS='x' read -ra RES <<< "$RESOLUTION"
VNC_WIDTH="${RES[0]}"
VNC_HEIGHT="${RES[1]}"
VNC_DEPTH="24"

echo "分辨率: ${VNC_WIDTH}x${VNC_HEIGHT}"

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

cat > /home/vncuser/.fluxbox/startup << EOF
#!/bin/bash
# Fluxbox启动脚本
# 使用环境变量设置的语言
export LANG=$LANG
export LANGUAGE=$LANGUAGE
export LC_ALL=$LC_ALL

firefox --kiosk --width=${VNC_WIDTH} --height=${VNC_HEIGHT} ${HOME_PAGE} &
EOF

chmod +x /home/vncuser/.fluxbox/startup
chown -R vncuser:vncuser /home/vncuser/.fluxbox

echo "🚀 启动Xvfb显示服务器..."
# 启动Xvfb（显示服务器）
Xvfb :0 -screen 0 ${VNC_WIDTH}x${VNC_HEIGHT}x${VNC_DEPTH} -ac +extension RANDR -nolisten tcp -noreset -dpi 96 &
XVFB_PID=$!

# 等待Xvfb启动
sleep 2

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
sleep 2

echo "🚀 启动x11vnc服务器..."
# 启动x11vnc
x11vnc -display :0 -forever -shared -passwd "$VNC_PASSWORD" -rfbport 5900 -noxdamage -xrandr -localhost &
X11VNC_PID=$!
sleep 2

echo "🚀 启动noVNC网页客户端..."
# 启动noVNC
if [ -d "/usr/share/novnc" ]; then
    websockify --web /usr/share/novnc $PORT localhost:5900 &
else
    websockify $PORT localhost:5900 &
fi
NOVNC_PID=$!
sleep 2

echo "🚀 启动Firefox浏览器..."
# 启动Firefox（使用fluxbox的startup脚本）
# 或者直接启动
firefox --display=:0 --width=${VNC_WIDTH} --height=${VNC_HEIGHT} ${HOME_PAGE} &
FIREFOX_PID=$!

echo "==========================================="
echo "✅ 所有服务启动完成！"
echo "📺 VNC 分辨率: ${RESOLUTION}"
echo "🔑 VNC 密码: ${VNC_PASSWORD}"
echo "🌐 访问地址: http://localhost:${PORT}"
echo "🌐 语言环境: $LANG"
echo "🏠 默认主页: $HOME_PAGE"
echo "==========================================="

# 检查所有进程是否在运行
echo "进程状态检查:"
if kill -0 $XVFB_PID 2>/dev/null; then echo "✅ Xvfb 运行中"; else echo "❌ Xvfb 已停止"; fi
if kill -0 $FLUXBOX_PID 2>/dev/null; then echo "✅ Fluxbox 运行中"; else echo "❌ Fluxbox 已停止"; fi
if kill -0 $X11VNC_PID 2>/dev/null; then echo "✅ x11vnc 运行中"; else echo "❌ x11vnc 已停止"; fi
if kill -0 $NOVNC_PID 2>/dev/null; then echo "✅ noVNC 运行中"; else echo "❌ noVNC 已停止"; fi
if kill -0 $FIREFOX_PID 2>/dev/null; then echo "✅ Firefox 运行中"; else echo "❌ Firefox 已停止"; fi

# 主进程保持运行
echo "🔄 进入主循环..."
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
    
    # 每60秒检查一次
    sleep 60
done