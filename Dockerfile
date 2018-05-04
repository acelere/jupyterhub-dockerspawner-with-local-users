FROM python:3.6.5
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install zip -y
RUN apt-get install octave -y
RUN apt-get install gnuplot -y
RUN pip3 install --no-cache-dir --upgrade pip
RUN pip3 install \
    jupyterhub \
    notebook \
    numpy \
    pandas \
    ipywidgets \
    traitlets \
    matplotlib \
    scipy \
    bqplot \
    octave_kernel
RUN pip3 install https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master
RUN apt-get install octave-odepkg \
    octave-control \
#    octave-image \ 
#    octave-io \
    octave-quaternion \
    octave-signal -y

# create a user, since we don't want to run as root
RUN useradd -m jovyan
RUN usermod -G users jovyan
ENV HOME=/home/jovyan
WORKDIR $HOME
USER jovyan
RUN jupyter contrib nbextension install --user
RUN jupyter nbextension enable codefolding/main
RUN mkdir /home/jovyan/work
RUN mkdir /home/jovyan/work/data
RUN chown -R jovyan /home/jovyan/work


CMD ["jupyterhub-singleuser"]
