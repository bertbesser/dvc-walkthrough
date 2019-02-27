FROM python:3.6

ADD configs/tini /tini
RUN chmod +x /tini

ADD configs/requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

ADD init-code /blog-dvc/init-code
RUN /blog-dvc/init-code/download_data.sh

ADD code /blog-dvc/code

ENTRYPOINT ["/tini", "--", "sleep", "infinity"]
