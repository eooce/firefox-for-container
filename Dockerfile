FROM alpine:latest

# 安装所有必要的软件包
RUN apk update && \
    apk add --no-cache \
        tzdata \
        curl \
        xvfb \
        x11vnc \
        novnc \
        fluxbox \
        websockify \
        font-dejavu \
        firefox \
        bash \
        git \
        rsync \
        procps \
        xterm \
        wqy-zenhei && \
    # 设置时区
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    # 设置VNC主页
    cp /usr/share/novnc/vnc.html /usr/share/novnc/index.html && \
    # 创建非特权用户
    adduser -D -s /bin/bash vncuser && \
    # 创建必要目录
    mkdir -p /home/vncuser/.mozilla/firefox && \
    mkdir -p /home/vncuser/.config && \
    mkdir -p /home/vncuser/tmp && \
    chown -R vncuser:vncuser /home/vncuser

# 复制启动脚本和Firefox配置文件并设置权限
COPY start.sh /home/vncuser/start.sh
COPY firefox-prefs.js /home/vncuser/firefox-prefs.js
RUN chmod +x /home/vncuser/start.sh && \
    chown vncuser:vncuser /home/vncuser/start.sh && \
    chown vncuser:vncuser /home/vncuser/firefox-prefs.js

# 声明暴露的端口
EXPOSE 8080

# 切换到非 root 用户
USER vncuser
WORKDIR /home/vncuser

# 设置默认启动命令
CMD ["./start.sh"]