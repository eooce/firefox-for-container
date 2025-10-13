# firefox-for-container

```
docker run -d -p 8080:8080 -v ./home/vncuser_data:/data/vncuser --name firefox ghci.io/eooce/firefox:latest -e VNC_PASSWORD=123456
```


```
services:
  firefox:
    image: ghcr.io/eooce/firefox:latest
    container_name: firefox
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - VNC_PASSWORD=123456  # vnc密码
    volumes:
      - ./home/vncuser_data:/data/vncuser # 持久化存储
```
