# nginx-rtmp-win32

Windows 平台的 nginx-rtmp-module 移植版本，支持 RTMP 和 RTMPS 推流/拉流。

* Nginx: 1.14.1
* Nginx-Rtmp-Module: 1.2.1
* openssl-1.0.2p
* pcre-8.42
* zlib-1.2.11

---

## dev 分支说明

在 1.2.1 基础上做一些小修改，原版请用 master 分支。

## configure arguments

```
nginx version: nginx/1.14.1
built by cl 18.00.40629 for x86
built with OpenSSL 1.0.2p  14 Aug 2018
TLS SNI support enabled
configure arguments: --with-cc=cl --builddir=objs --with-debug --prefix= --conf-
path=conf/nginx.conf --pid-path=logs/nginx.pid --http-log-path=logs/access.log -
-error-log-path=logs/error.log --sbin-path=nginx.exe --http-client-body-temp-pat
h=temp/client_body_temp --http-proxy-temp-path=temp/proxy_temp --http-fastcgi-te
mp-path=temp/fastcgi_temp --http-scgi-temp-path=temp/scgi_temp --http-uwsgi-temp
-path=temp/uwsgi_temp --with-cc-opt=-DFD_SETSIZE=1024 --with-pcre=objs/lib/pcre-
8.42 --with-zlib=objs/lib/zlib-1.2.11 --with-select_module --with-http_v2_module
 --with-http_realip_module --with-http_addition_module --with-http_sub_module --
with-http_dav_module --with-http_stub_status_module --with-http_flv_module --with
-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with
-http_auth_request_module --with-http_random_index_module --with-http_secure_lin
k_module --with-http_slice_module --with-mail --with-stream --with-openssl=objs
/lib/openssl-1.0.2p --with-openssl-opt=no-asm --with-http_ssl_module --with-mail
_ssl_module --with-stream_ssl_module --add-module=objs/lib/nginx-rtmp-module/
```

---

## 使用方法

双击 `nginx.exe` 启动。

---

## RTMPS 支持说明

本版本通过 nginx 的 `stream` 模块实现 RTMPS（RTMP over TLS）支持。
`stream` 模块负责 SSL/TLS 卸载，将解密后的 RTMP 流量转发到本地 1935 端口。

### 端口说明

| 协议 | 端口 | 说明 |
|------|------|------|
| RTMP | 1935 | 非加密推流/拉流 |
| RTMPS | 1936 | TLS 加密推流/拉流（stream 模块 SSL 卸载） |
| HTTP | 8080 | 状态查看、HLS 播放 |
| HTTPS | 8443 | HTTPS 测试 |

### 推流地址

**RTMP（非加密）：**
```
rtmp://<IP>:1935/live/<stream_key>
# 示例：
rtmp://192.168.10.107:1935/live/video0
rtmp://localhost:1935/live/test
```

**RTMPS（TLS 加密）：**
```
rtmps://<IP>:1936/live/<stream_key>
# 示例：
rtmps://192.168.10.107:1936/live/video0
rtmps://localhost:1936/live/test
```

### 播放地址

**RTMP 播放：**
```
rtmp://<IP>:1935/live/<stream_key>
```

**RTMPS 播放：**
```
rtmps://<IP>:1936/live/<stream_key>
```

**HLS 播放：**
```
http://<IP>:8080/hls/<stream_key>.m3u8
```

### 状态查看

```
http://<IP>:8080/stat
```

---

## SSL 证书配置

RTMPS 需要 SSL 证书，已提供自动生成脚本：

### Windows 下生成证书

双击运行 `gen_cert.bat`，会自动生成：
```
ssl/cert.crt   - 自签名证书
ssl/cert.key   - RSA 私钥
```

> 需要系统已安装 OpenSSL（Git Bash 自带 openssl 命令行）

### WSL / Linux / macOS 下生成证书

```bash
chmod +x gen_cert.sh
./gen_cert.sh
```

### 使用自有证书

将证书和私钥放入 `ssl/` 目录，然后修改 `conf/nginx.conf` 中的证书路径：
```nginx
ssl_certificate      D:/nginx-rtmp-win32/ssl/your-cert.crt;
ssl_certificate_key  D:/nginx-rtmp-win32/ssl/your-cert.key;
```

> 注意：Windows 路径使用正斜杠 `/` 或双反斜杠 `\\`

---

## nginx.conf 配置说明

### RTMP 服务器（端口 1935）

```nginx
rtmp {
    server {
        listen 1935;
        chunk_size 4096;
        application live {
            live on;
            meta copy;
        }
        application hls {
            live on;
            hls on;
            hls_path temp/hls;
            hls_fragment 8s;
        }
    }
}
```

### Stream 模块（RTMPS 端口 1936）

```nginx
stream {
    server {
        listen 1936 ssl;
        ssl_certificate      D:/nginx-rtmp-win32/ssl/cert.crt;
        ssl_certificate_key  D:/nginx-rtmp-win32/ssl/cert.key;

        # 减少缓冲延迟
        proxy_buffer_size 4k;
        proxy_connect_timeout 1s;
        proxy_timeout 10m;

        proxy_pass 127.0.0.1:1935;
    }
}
```

---

## 推流/播放测试工具

内置了一个方便测试的 PC 端推流与播放工具：
![img](https://github.com/NodeMedia/NodeMediaDevClient/raw/master/QQ20160310-0.png)
源码在此: https://github.com/NodeMedia/NodeMediaDevClient

### ffmpeg 推流示例

**RTMP 推流：**
```bash
ffmpeg -re -i input.mp4 -c copy -f flv rtmp://localhost:1935/live/video0
```

**RTMPS 推流（需要 ffmpeg 支持 rtmps 协议）：**
```bash
ffmpeg -re -i input.mp4 -c copy -f flv rtmps://localhost:1936/live/video0
```

### VLC 播放示例

**RTMP 播放：**
```
vlc rtmp://localhost:1935/live/video0 --network-caching=300
```

**RTMPS 播放：**
```
vlc rtmps://localhost:1936/live/video0 --network-caching=300
```

---

## 注意

* 不支持 `exec` 指令
* RTMPS 使用自签名证书时，播放器可能需要忽略证书验证
* `stream` 模块需要 nginx 编译时开启 `--with-stream --with-stream_ssl_module`

---

## H265 支持

支持 ID=12 的 H265 流，需要客户端支持。

---

## 常见问题

### Q: RTMPS 推流后播放有延迟？

A: 检查 nginx `stream` 模块配置，确保 `proxy_buffer_size` 设置较小（如 4k）。
也可以尝试用 `--network-caching=300` 参数减少 VLC 缓冲。

### Q: ffmpeg 推 RTMPS 报错 `rtmp_listen not available for rtmps`？

A: ffmpeg 的 RTMPS 实现有 bug，可换用 librtmp（支持 mbedtls/openssl）推流。

### Q: 播放器无法连接 RTMPS？

A: 确认 1936 端口已监听：`netstat -ano | findstr 1936`，确认 nginx 已启动且 stream 模块配置正确。
