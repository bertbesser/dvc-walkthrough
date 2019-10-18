FROM python:3.6

ARG NAME=dvc
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID -o $NAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $NAME

ADD configs/tini /tini
RUN chmod +x /tini

ADD configs/requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

ADD configs/download_data.sh /download_data.sh
ADD configs/download_data.py /download_data.py
RUN /download_data.sh

ADD scripts/livedemo.sh /tmp/livedemo.sh
RUN cat /tmp/livedemo.sh | grep -v '^#' | grep . > /home/dvc/.bash_history

ADD configs/.gitconfig /home/dvc/.gitconfig
RUN chown dvc:dvc /home/dvc/.gitconfig

RUN echo "root:root" | chpasswd

RUN echo "alias ll='ls -l --color'" > /home/dvc/.bashrc
RUN chown dvc:dvc /home/dvc/.bashrc

RUN dvc config --system core.analytics false

ADD configs/.ssh/config /home/dvc/.ssh/config
ADD configs/.ssh/id_rsa /home/dvc/.ssh/id_rsa
ADD configs/.ssh/id_rsa.pub /home/dvc/.ssh/id_rsa.pub
ADD configs/.ssh/known_hosts /home/dvc/.ssh/known_hosts
RUN chown -R dvc:dvc /home/dvc/.ssh
RUN chmod 600 /home/dvc/.ssh/id_rsa

ENTRYPOINT ["/tini", "--", "sleep", "infinity"]
