@echo off
REM 生成自签名 SSL 证书用于 RTMPS 测试
REM 需要 OpenSSL 支持（可用 Git Bash 中的 openssl）

set OPENSSL=openssl
set CERT_DIR=%~dp0ssl

if not exist %CERT_DIR% mkdir %CERT_DIR%

echo 正在生成 RSA 私钥...
%OPENSSL% genrsa -out %CERT_DIR%/cert.key 2048

echo 正在生成自签名证书...
%OPENSSL% req -new -x509 -key %CERT_DIR%/cert.key -out %CERT_DIR%/cert.crt -days 365 -subj "/C=CN/ST=Beijing/L=Beijing/O=nginx-rtmp/CN=localhost"

echo.
echo 证书生成完成！
echo   私钥: %CERT_DIR%\cert.key
echo   证书: %CERT_DIR%\cert.crt
echo.
pause
