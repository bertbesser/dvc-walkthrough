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

RUN su dvc -c "git clone --depth 1 https://github.com/junegunn/fzf.git /tmp/fzf"
RUN su dvc -c "/tmp/fzf/install"

RUN echo "alias ls='ls --color'" >> /home/dvc/.bashrc
RUN echo "alias ll='ls -l --color'" >> /home/dvc/.bashrc
RUN echo 'export PS1="\[$(tput bold)\]\[\033[38;5;74m\]\u\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\]@\[$(tput bold)\]\[\033[38;5;141m\]\h\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput bold)\]\[\033[38;5;202m\]\W\[$(tput sgr0)\]\[\033[38;5;15m\]\\$ \[$(tput sgr0)\]"' >> /home/dvc/.bashrc
RUN echo 'export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS" --color=dark --color=fg:-1,bg:-1,hl:#c678dd,fg+:#ffffff,bg+:#4b5263,hl+:#d858fe --color=info:#98c379,prompt:#61afef,pointer:#be5046,marker:#e5c07b,spinner:#61afef,header:#61afef "' >> /home/dvc/.bashrc
RUN chown dvc:dvc /home/dvc/.bashrc

RUN dvc config --system core.analytics false

ADD configs/.ssh/config /home/dvc/.ssh/config
ADD configs/.ssh/id_rsa /home/dvc/.ssh/id_rsa
ADD configs/.ssh/id_rsa.pub /home/dvc/.ssh/id_rsa.pub
ADD configs/.ssh/known_hosts /home/dvc/.ssh/known_hosts
RUN chown -R dvc:dvc /home/dvc/.ssh
RUN chmod 600 /home/dvc/.ssh/id_rsa

ENTRYPOINT ["/tini", "--", "sleep", "infinity"]
