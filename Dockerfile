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

ADD code /dvc-walkthrough/code
RUN chown -R dvc:dvc /dvc-walkthrough

ENTRYPOINT ["/tini", "--", "sleep", "infinity"]
