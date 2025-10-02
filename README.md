# firefox-for-container

```
docker run -d -p 8080:8080 -v ./config:/config --name firefox ghci.io/eooce/firefox:latest -e VNC_PASSWORD=123456
```


```
version: '3'

services:
  name: firefox
  image: ghci.io/eooce/firefox:latest
    ports:
      - "8080:8080"
    environment:
      - VNC_PASSWORD=123456
    volumes:
      - ./config:/config
```
