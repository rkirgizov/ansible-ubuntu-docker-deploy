# Используйте подходящий базовый образ
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Установите необходимые системные пакеты
RUN apt-get update && \
    apt-get install -y gcc python3-dev libkrb5-dev python3-pip python3-venv && \
    apt-get install -y krb5-user openssh-server openssh-client sshpass

# Создайте и настройте виртуальное окружение
RUN python3 -m venv /opt/venv

# Установите необходимые Python-пакеты в виртуальном окружении
RUN /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install --upgrade virtualenv && \
    /opt/venv/bin/pip install pywinrm kerberos ansible

# Установите переменную окружения для использования виртуального окружения по умолчанию
ENV PATH="/opt/venv/bin:$PATH"