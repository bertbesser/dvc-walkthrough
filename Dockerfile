FROM python:3.6

ADD configs/tini /tini
RUN chmod +x /tini

ADD configs/requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

ADD configs/download_data.sh /download_data.sh
ADD configs/download_data.py /download_data.py
RUN /download_data.sh

ADD code /blog-dvc/code

ENTRYPOINT ["/tini", "--", "sleep", "infinity"]
