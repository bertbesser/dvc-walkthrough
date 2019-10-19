FROM python:3.6

# setup system

RUN echo "root:root" | chpasswd

ADD configs/tini /tini
RUN chmod +x /tini

ADD configs/requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

ADD configs/download_data.sh /download_data.sh
ADD configs/download_data.py /download_data.py
RUN /download_data.sh

RUN dvc config --system core.analytics false

# prepare user setup

RUN git clone --depth 1 https://github.com/junegunn/fzf.git /tmp/fzf
RUN chmod -R a+rw /tmp/fzf
ADD scripts/livedemo.sh /tmp/livedemo.sh

# setup user

ARG USER=dvc
ARG UID=1000
ARG GID=1000

RUN groupadd -g $GID -o $USER
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $USER

RUN cat /tmp/livedemo.sh | grep -v '^#' | grep . > /home/$USER/.bash_history
RUN chown $USER:$USER /home/$USER/.bash_history

ADD configs/.gitconfig /home/$USER/.gitconfig
RUN chown $USER:$USER /home/$USER/.gitconfig

RUN echo "alias ls='ls --color'" >> /home/$USER/.bashrc
RUN echo "alias ll='ls -l --color'" >> /home/$USER/.bashrc
RUN chown $USER:$USER /home/$USER/.bashrc

RUN echo 'export PS1="\[$(tput bold)\]\[\033[38;5;74m\]\u\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\]@\[$(tput bold)\]\[\033[38;5;141m\]\h\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput bold)\]\[\033[38;5;202m\]\W\[$(tput sgr0)\]\[\033[38;5;15m\]\\$ \[$(tput sgr0)\]"' >> /home/$USER/.bashrc
RUN chown $USER:$USER /home/$USER/.bashrc

RUN su $USER -c "/tmp/fzf/install"
RUN echo 'export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS" --color=dark --color=fg:-1,bg:-1,hl:#c678dd,fg+:#ffffff,bg+:#4b5263,hl+:#d858fe --color=info:#98c379,prompt:#61afef,pointer:#be5046,marker:#e5c07b,spinner:#61afef,header:#61afef "' >> /home/$USER/.bashrc
RUN chown $USER:$USER /home/$USER/.bashrc

ADD configs/.ssh/config /home/$USER/.ssh/config
ADD configs/.ssh/id_rsa /home/$USER/.ssh/id_rsa
ADD configs/.ssh/id_rsa.pub /home/$USER/.ssh/id_rsa.pub
ADD configs/.ssh/known_hosts /home/$USER/.ssh/known_hosts
RUN chown -R $USER:$USER /home/$USER/.ssh
RUN chmod 600 /home/$USER/.ssh/id_rsa

ENTRYPOINT ["/tini", "--", "sleep", "infinity"]
