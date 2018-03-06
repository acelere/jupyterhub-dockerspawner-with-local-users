FROM python:3.6
RUN apt update
RUN apt upgrade -y
RUN pip3 install --upgrade pip
RUN pip3 install \
    jupyterhub \
    notebook \
    numpy \
    pandas \
    ipywidgets \
    traitlets \
    matplotlib \
    scipy \
    bqplot

# create a user, since we don't want to run as root
RUN useradd -m jovyan
RUN usermod -G users jovyan
ENV HOME=/home/jovyan
WORKDIR $HOME
USER jovyan
RUN mkdir /home/jovyan/work
RUN mkdir /home/jovyan/work/data
RUN chown -R jovyan /home/jovyan/work


CMD ["jupyterhub-singleuser"]
