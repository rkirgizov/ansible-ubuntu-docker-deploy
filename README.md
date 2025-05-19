Устанавливаем Ansible с помощью Docker Compose (контейнеры c Ubuntu 22.04).  
Использовал инструкцию для nix, но разворачивал контейнер в десктопном Docker на Windows 11.  
<https://cloudinfrastructureservices.co.uk/how-to-install-ansible-using-docker-compose-ubuntu-20-04-container/>

### Создаём структуру папок и файлы

./ssh-enabled-ubuntu/Dockerfile
```docker
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:rootpassword' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
```
./Dockerfile
```docker
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
```
./docker-compose.yml
```docker
version: '3'
services:
      ansible:
        container_name: ansible
        image: ansible
        tty: true
        stdin_open: true
        build:
          context: ./

      remote-host-one:
        container_name: remote-host-one
        image: remote-host-ssh
        build:
          context: ./ssh-enabled-ubuntu

networks:
      net:
```

### Запуск контейнера Ansible
На этом этапе все конфигурационные файлы готовы к запуску контейнера Ansible. 
Теперь вы можете изменить каталог на ansible и выполнить следующую команду для запуска контейнера Ansible:
```docker
docker-compose up -d
```
В случае подобных ошибок
```
=> ERROR [ansible internal] load metadata for docker.io/library/ubuntu:22.04                                                                                                                                                                                                                                                                                   0.2s 
 => [ansible auth] library/ubuntu:pull token for registry-1.docker.io                                                                                                                                                                                                                                                                                           0.0s 
------
 > [ansible internal] load metadata for docker.io/library/ubuntu:22.04:
------
failed to solve: ubuntu:22.04: failed to resolve source metadata for docker.io/library/ubuntu:22.04: failed to authorize: 
failed to fetch oauth token: Post "https://auth.docker.io/token": write tcp 192.168.1.5:21224->44.208.254.194:443: 
wsasend: An existing connection was forcibly closed by the remote host.
```
сначала выполните пул образа, из которого устанавливаете (прописан в докерфайле)
```
docker pull ubuntu:22.04
```
### Подключение к контейнеру Ansible
Теперь вы можете подключиться к контейнеру Ansible с помощью следующей команды:
```
docker exec -it 324f1c88f928 bash
```
Как только вы подключитесь к контейнеру Ansible, вы получите следующую оболочку:
```
root@324f1c88f928:/#
```
Проверьте установленную версию Ansible с помощью следующей команды:
```
root@324f1c88f928:/# ansible --version
```
Вы должны увидеть версию Ansible в следующих выходных данных:
```
ansible [core 2.13.1]
config file = None
configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
ansible python module location = /usr/local/lib/python3.10/dist-packages/ansible
ansible collection location = /root/.ansible/collections:/usr/share/ansible/collections
executable location = /usr/local/bin/ansible
python version = 3.10.4 (main, Apr  2 2022, 09:04:19) [GCC 11.2.0]
jinja version = 3.1.2
libyaml = True
```
Если вы хотите подключиться к другому контейнеру Ubuntu, выполните команду SSH:
```
ssh root@remote-host-one

The authenticity of host 'remote-host-one (172.18.0.3)' can't be established.
ED25519 key fingerprint is SHA256:oIt+LV7hy0Xpb/jslLYQzX4fIufhM9Wc9EiJx2IOjns.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'remote-host-one' (ED25519) to the list of known hosts.
root@remote-host-one's password:
```
Укажите пароль root, который вы определили в файле Dockerfile, для подключения к контейнеру.   
Как только вы подключитесь, вы получите следующие выходные данные:
```
Welcome to Ubuntu 16.04.7 LTS (GNU/Linux 5.4.0-121-generic x86_64)

* Documentation:  https://help.ubuntu.com
* Management:     https://landscape.canonical.com
* Support:        https://ubuntu.com/advantage

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.
```
