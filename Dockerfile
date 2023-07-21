FROM node:18-alpine AS FrontendBuilder

RUN mkdir -p /app
COPY frontend /app/frontend

WORKDIR /app/frontend
RUN npm install pnpm -g
RUN pnpm install
RUN pnpm build

FROM python:3.10-slim

# 在安装其他 Python 依赖之前首先升级 pip
RUN pip install --upgrade pip

ARG PIP_CACHE_DIR=/pip_cache
ARG TARGETARCH

RUN mkdir -p /app/backend

# 添加这一行来安装 libyaml 和其他可能的依赖项
RUN apk add --update caddy gcc musl-dev libffi-dev yaml-dev

# 安装必要的系统依赖项
RUN apt-get update && apt-get install -y gcc libffi-dev libyaml-dev && apt-get clean

# 添加必要的系统库和构建工具
RUN apk add --update --no-cache \
    caddy \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    cargo

RUN pip install Cython
# 首先尝试安装 PyYAML
RUN pip install PyYAML -v

COPY backend/requirements.txt /tmp/requirements.txt
# RUN pip install -r /tmp/requirements.txt
# 使用 -v 选项安装 Python 依赖以获取详细的日志输出
RUN pip install -r /tmp/requirements.txt -v

COPY Caddyfile /app/Caddyfile
COPY backend /app/backend
COPY --from=FrontendBuilder /app/frontend/dist /app/dist

WORKDIR /app

EXPOSE 80

COPY startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh; mkdir /data
CMD ["/app/startup.sh"]
