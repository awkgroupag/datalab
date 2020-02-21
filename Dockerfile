FROM jupyter/scipy-notebook:latest

USER root

RUN apt-get update \
 && apt-get -y install htop docker.io \
 && pip install docker-compose

ENV JUPYTER_ENABLE_LAB='yes'
ENV GRANT_SUDO='yes'

USER jovyan

COPY ./folder.tar .
RUN tar -xf folder.tar && rm folder.tar

CMD start-notebook.sh --NotebookApp.token=""

