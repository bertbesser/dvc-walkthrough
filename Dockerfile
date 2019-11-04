FROM python:3.6

# setup system

RUN echo "root:root" | chpasswd

ADD configs/tini /tini
RUN chmod +x /tini

RUN apt update
RUN apt install -y zsh less nano ncdu tree

# install ml env

ADD configs/requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

ADD configs/requirementsDvc.txt /requirementsDvc.txt
RUN pip install -r /requirementsDvc.txt
RUN dvc config --system core.analytics false

# install mnist data set

ADD configs/download_data.sh /download_data.sh
ADD configs/download_data.py /download_data.py
RUN /download_data.sh

# prepare user setup

RUN git clone --depth 1 https://github.com/junegunn/fzf.git /tmp/fzf
RUN chmod -R a+rw /tmp/fzf
ADD configs/zsh_colors.sh /tmp/zsh_colors.sh

# setup user

ARG USER=dvc
ARG UID=1000
ARG GID=1000
ARG PROMPT_COLOR=231

RUN groupadd -g $GID -o $USER
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $USER

RUN su $USER -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" --unattended'

RUN su $USER -c "/tmp/fzf/install"
RUN echo 'export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS" --color=dark --color=fg:-1,bg:-1,hl:#c678dd,fg+:#ffffff,bg+:#4b5263,hl+:#d858fe --color=info:#98c379,prompt:#61afef,pointer:#be5046,marker:#e5c07b,spinner:#61afef,header:#61afef "' >> /home/$USER/.zshrc
RUN su $USER -c 'echo "export PATH=\$PATH:/tmp/fzf/bin" >> $HOME/.zshrc'
RUN chown $USER:$USER /home/$USER/.zshrc

RUN su $USER -c "cd /home/$USER && mkdir bin && cd bin && wget https://raw.githubusercontent.com/so-fancy/diff-so-fancy/master/third_party/build_fatpack/diff-so-fancy && chmod +x diff-so-fancy && git config --global core.pager 'diff-so-fancy | less --tabs=4 -RFX'"
RUN su $USER -c 'echo "export PATH=\$PATH:$HOME/bin" >> $HOME/.zshrc'

RUN su $USER -c 'cp /tmp/zsh_colors.sh $HOME/.zsh_colors.sh'
RUN echo '$HOME/.zsh_colors.sh' >> /home/$USER/.zshrc
RUN echo "export PS1=\"\$FG[$PROMPT_COLOR]%B%n%b%f\$FG[231]:%f\$FG[$PROMPT_COLOR]%B%1~%b%f\$FG[231]\$%f \"" >> /home/$USER/.zshrc
RUN chown $USER:$USER /home/$USER/.zshrc

RUN echo "alias ls='ls -1 --color'" >> /home/$USER/.zshrc
RUN echo "alias ll='ls -l --color'" >> /home/$USER/.zshrc
RUN chown $USER:$USER /home/$USER/.zshrc

ADD configs/.ssh/config /home/$USER/.ssh/config
ADD configs/.ssh/id_rsa /home/$USER/.ssh/id_rsa
ADD configs/.ssh/id_rsa.pub /home/$USER/.ssh/id_rsa.pub
ADD configs/.ssh/known_hosts /home/$USER/.ssh/known_hosts
RUN chown -R $USER:$USER /home/$USER/.ssh
RUN chmod 600 /home/$USER/.ssh/id_rsa

ADD configs/.gitconfig /home/$USER/.gitconfig
RUN chown $USER:$USER /home/$USER/.gitconfig
RUN su $USER -c "git config --global user.name '$USER'"
RUN su $USER -c "git config --global user.email '$USER@dvc.livedemo'"

# setup livedemo

ADD scripts/livedemo.sh /tmp/livedemo.sh
RUN cat /tmp/livedemo.sh | grep -v '^#' | grep . | awk -F'#' '{print ": 1571499890:0;"$1}' > /home/$USER/.zsh_history
RUN chown $USER:$USER /home/$USER/.zsh_history

ADD configs/.aws/config /home/$USER/.aws/config
ADD configs/.aws/credentials /home/$USER/.aws/credentials
RUN su $USER -c 'echo "export AWS_DEFAULT_PROFILE=besser" >> $HOME/.zshrc'

RUN su $USER -c 'echo "export CUDA_VISIBLE_DEVICES=\"\"" >> $HOME/.zshrc'
RUN su $USER -c 'echo "export PYTHONHASHSEED=0" >> $HOME/.zshrc'

ENTRYPOINT ["/tini", "--", "sleep", "infinity"]
