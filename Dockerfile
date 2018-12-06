FROM python:3.7

RUN apt-get update
RUN apt-get install zip \
    octave \
    gnuplot \
    nodejs-legacy -y

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs

RUN wget https://cmake.org/files/v3.11/cmake-3.11.3-Linux-x86_64.sh \
    && chmod 775 ./cmake-3.11.3-Linux-x86_64.sh \
    && ./cmake-3.11.3-Linux-x86_64.sh --skip-license

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
    octave_kernel \
    sympy \
    ipyvolume
RUN pip3 install cvxpy

RUN pip3 install jupyterlab

RUN pip3 install https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master

RUN apt-get install octave-odepkg \
    octave-control \
    octave-image \
    octave-io \
    octave-quaternion \
    octave-signal -y

RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager
RUN jupyter labextension install bqplot
RUN jupyter labextension install @jupyterlab/hub-extension


# create a user, since we don't want to run as root
RUN useradd -m jovyan
RUN usermod -G users jovyan
ENV HOME=/home/jovyan
WORKDIR $HOME
USER jovyan
RUN jupyter contrib nbextension install --user
RUN jupyter nbextension enable codefolding/main
RUN jupyter notebook --version
#RUN jupyter serverextension enable --py jupyterlab --sys-prefix

RUN mkdir /home/jovyan/work
RUN mkdir /home/jovyan/work/data
RUN chown -R jovyan /home/jovyan/work


CMD ["jupyterhub-singleuser"]
