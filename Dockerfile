FROM python:3.8.2

RUN apt-get update
RUN apt-get install zip \
    octave \
    #octave-odepkg \
    octave-control \
    octave-image \
    octave-io \
    octave-quaternion \
    octave-signal \
    gnuplot \
    r-base r-base-dev libzmq3-dev \
    nodejs -y    
#nodejs-legacy -y

RUN curl -sL https://deb.nodesource.com/setup_13.x | bash -
RUN apt-get install -y nodejs

RUN wget https://cmake.org/files/v3.17/cmake-3.17.1-Linux-x86_64.sh \
    && chmod 775 ./cmake-3.17.1-Linux-x86_64.sh \
    && ./cmake-3.17.1-Linux-x86_64.sh --skip-license

RUN pip3 install \
    jupyterhub \
    notebook \
    jupyterlab \
    numpy \
    pandas \
    ipywidgets \
    traitlets \
    matplotlib \
    scipy \
    bqplot \
    octave_kernel \
    sympy \
    pytz \
    jupytext \
    scikit-aero \
    xlrd \
    ipyvolume 
RUN pip3 install cvxpy


#RUN pip3 install https://github.com/ipython-contrib/jupyter_contrib_nbextensions/tarball/master


RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager
RUN jupyter labextension install bqplot
RUN jupyter serverextension enable jupyterlab


RUN git clone https://github.com/acelere/IRKernel_install_script
RUN Rscript ./IRKernel_install_script/rk_install.r

# create a user, since we don't want to run as root
RUN useradd -m jovyan
RUN usermod -G users jovyan
# Add user to staff to enable R packages install
RUN usermod -a -G staff jovyan
ENV HOME=/home/jovyan
WORKDIR $HOME

USER jovyan
#RUN jupyter contrib nbextension install --user
#RUN jupyter nbextension enable codefolding/main


RUN mkdir /home/jovyan/work
RUN mkdir /home/jovyan/work/data
RUN chown -R jovyan /home/jovyan/work

RUN git -C /home/jovyan clone https://github.com/acelere/Flight-Test-Analysis-Tool

CMD ["jupyterhub-singleuser"]
