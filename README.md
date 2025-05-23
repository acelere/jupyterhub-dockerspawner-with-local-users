# jupyterhub-dockerspawner-with-local-users

<p> While learning how to implement a JupyterHub server using Dockerspawner, the tutorial available  <a href="https://github.com/jupyterhub/jupyterhub-deploy-docker">here</a> uses OAuthenticator and GitHub OAuth, which means you need a valid IP with DNS entry. </p>
<p> Since I was trying to set up a JHub server inside my local network/organization, and since I did not have an external IP/DNS, I had to figure out how to use the default local linux system authenticator </p>
<p> Therefore, this JupterHub Narrative or Use Case will take you from a fresh Ubuntu/Debian install to a functioning <b>JupyterHub server</b> using the <b>default local users authenticator</b>, <b>dockerspawner</b> using a custom container, <b>persistent storage</b> for each user as well as <b>persistent shared storage</b> for the group. </p>
<p> This is a good setup for a small institution, classroom or even setting up a "travelling lab" for a conference -- 2-20 users should work just fine on an old laptop.</p>
<p> In my particular case, the idea is to create a data analysis environment, where local users will have access to large data files and will be able to use a variety of tools in the form of pre-defined notebooks.</p>
<p>The motivation to use jupyterhub came from the ability to standardize the environment and allow the users to "hit the ground running" instead of battling with software installation, lack of administrative righst on the user side, dependencies and etc. Pretty common scenario for a school.</p>
<p>The motivation to use dockerspawner came from the fact that the tools (notebooks) will be quite compute intensive and thus, I needed the ability to spawn independent processes that I could kill (as an administrator) and prepare for future growth by allowing the containers to be spawned in other computers.</p>

<p></p>

## Installation

<p>Start from a fresh Ubuntu or Debian install. I have used 22.04 and Debian 12.9 on a computer connected to my local network.</p>
<p>To make things easy, after the installation was complete, I went into the router configuration and fixed the IP for that computer, using its MAC address. This is to ensure that when running JupyterHub, the IP address is fixed.</p>
<p> We are assuming you have sudo access here... </p>
<p>If you are on Ubuntu, install the Universe repository:</p>

```bash
add-apt-repository universe
```

<p>Next, install docker as per <a href="https://docs.docker.com/install/linux/docker-ce/ubuntu/#supported-storage-drivers">this link</a></p>
Alternatively, you can install by:

```bash
wget https://get.docker.com
mv index.html getdocker.sh
chmod 755 getdocker.sh
sudo ./getdocker.sh 
```
After installing docker, you need to add your user to the docker group to allow for it to start a docker container.
```bash
sudo usermod -aG docker <your user name here> 
```
To start the docker daemon:
```bash
sudo systemctl start docker 
```
and to enable it at startup:
```bash
sudo systemctl enable docker 
```
Next up is to install JupyterHub. The pre-requisites instructions in  <a href="https://github.com/jupyterhub/jupyterhub/blob/master/README.md">jupyterhub_github</a> are a little confusing to me. So, Follow this link with nodejs install instructions: <a href="https://github.com/nodesource/distributions#debinstall">nodejs_install</a>. Just remember we will need to install the same version in our container.

After nodejs is installed, we need to install the configurable-proxy:

```bash
sudo npm install -g configurable-http-proxy
```

Linux uses Python at OS level and we do not want to break that. So, install the virtual environment package first:
```bash
sudo apt install python3-venv -y
```
Then, create a new virtual environment to install jupyterhub and activate it:

```bash
python3 -m venv /home/<your username>/jhub_venv
source /home/<your username>/jhub_venv/bin/activate
```


Install jupyterhub:
```bash
pip3 install jupyterhub
```

Add it to the path, if you need to run jupyterhub as root. Otherwise skip this step:
```bash
cd /
ln -s /home/<your username>/.local/bin/jupyterhub .
``` 


You may have to manually install dockerspawner too if it did not install with jupyterhub. In order to find out, you can test by typing 
```python
python3 -c 'import dockerspawner'
```
and checking if there are any errors. If you are greeted with an error, you need to manually install dockerspawner, otherwise you are good to go.
```python
pip3 install dockerspawner
``` 

Let's now create the persistent storage areas, since each docker container will be spawned "new" each time. In my case, I wanted a storage area for each user and a common area to allow for big data files exchange.
It is a good idea (as explained <a href="http://jupyterhub.readthedocs.io/en/latest/reference/technical-overview.html">here</a>) to put these files into something like /srv/jupyterhub. In my case, I chose /srv/jhub_persistent:

```bash
# create the notebook directory
NBDIR=/srv/jhub_persistent/
sudo mkdir "$NBDIR"
# make it owned by the GID of the notebook containers.
# This is 100 in the jupyter docker-stacks,
# but should be whatever GID your containers run as
sudo chown :100 "$NBDIR"
# make it group-setgid-writable
sudo chmod g+rws "$NBDIR"
# set the default permissions for new files to group-writable
sudo setfacl -d -m g::rwx "$NBDIR"
```

On Debian, you may have to install the *acl* tools:
```bash
sudo apt install acl
```

To enable this persistent directory to be accessed by the docker user, we needed to set permissions and acl (already in the above snippet and as decribed <a href="https://github.com/jupyterhub/dockerspawner/issues/160">on issue 160</a>). As minrk explains:

    The s in chmod means that any new files created in that directory, by any user (including root), will be owned by the same group as the parent, which we set to 100.
    The setfacl makes it so that any new files have default permissions including full group access.


Try to create a dummy file in that directory:
```bash
touch /srv/jhub_persistent/test.txt
```
If that does not work, then your current user might not be part of the "users" group.
Then, add yourself by
```bash
sudo usermod -a -G users <your user name here>
```
But you will need to logout of the terminal and login again for this to take effect!

At this point, we are now ready to build our container.
Use the dockerfile from this repository, as a starter, and modify it to your needs.
Here is a breakdown of the dockerfile with explanations. There is an example file in this repo.

First, start with a fresh python image and install the packages you want. Below is a simple example:

```
FROM 3.12-bookworm

RUN curl -sL https://deb.nodesource.com/setup_23.x | bash -
RUN apt-get install -y nodejs


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
    jupyterlab
```

Create the default jupyterhub container user "jovyan" and add this user to the "users" group:
```
RUN useradd -m jovyan
RUN usermod -G users jovyan
```
Then, we set the ENV variable, workdir and tell docker to switch to the user we just created:
```
ENV HOME=/home/jovyan
WORKDIR $HOME
USER jovyan
```
Then, we create the directories we want to mount the persistent data directories:
```
RUN mkdir /home/jovyan/work
RUN mkdir /home/jovyan/work/data
RUN chown -R jovyan /home/jovyan/work
```
And last, we tell the container to run the command to start the jupyterhub-singleuser:
```
CMD ["jupyterhub-singleuser"]
```

After putting this Dockerfile in your server, it is time to build the container. Run the following from within the same directory you placed the Dockerfile in:
```bash
docker build -t <choose_your_docker_container_name> . 
```


Note that if you get an error from the docker daemon, that is because you need to reboot the system before trying to build your container.


With the docker container built, it is time to make your jupyterhub_config.py file. 
Again, you can start with the one in this repo, adjusting the container name to whatever you chose when building it just above.


Key things for your jupyterhub_config.py file, as explained <a href=" https://github.com/jupyterhub/jupyterhub/blob/master/examples/bootstrap-script/jupyterhub_config.py">here</a>.


We mount the user directory with this bit of code (inside the jupyterhub_config.py file):
```
import os
from dockerspawner import DockerSpawner

def create_dir_hook(spawner):
   username = spawner.user.name
   volume_path = os.path.join('/srv/jhub_persistent/', username)
   if not os.path.exists(volume_path):
      os.mkdir(volume_path, 0o755)
      print("created user directory because it did not exist")

c = get_config()

# Spawn single-user servers as Docker cotainers
c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'

# Prepare the directory for pesistent storage
c.Spawner.pre_spawn_hook = create_dir_hook
```

And new from jupyterhub 5.0 and on, we need to allow users explicitly.
```
c.Authenticator.allow_all = True
```

We choose the container to be spawned here (make sure the name of the container is the same you used to build it):
```
# Spawn containers from this image
c.DockerSpawner.image = 'choose_your_docker_container_name'
```
Lab as default

```
c.Spawner.default_url = '/lab'
```


This sets the notebook directory:
```
work_dir = os.environ.get('DOCKER_NOTEBOOK_DIR') or '/home/jovyan/work'
notebook_dir = os.environ.get('DOCKER_NOTEBOOK_DIR') or '/home/jovyan/work'

c.DockerSpawner.notebook_dir = notebook_dir
```

We mount the persistent directories with:
```
#mount the 2 persistent directories
c.DockerSpawner.volumes = { '/srv/jhub_persistent/{username}': notebook_dir, '/srv/jhub_persistent/data':'/home/jovyan/work/data' }
```
And finally, we need to set the IP of the JupyterHub, otherwise you also get an error:
```
#had to se the IP otherwise got an error
c.JupyterHub.hub_ip = '192.168.0.242' #THIS NUMBER IS JUST AN EXAMPLE; USE THE JHUB'S SERVER IP INSIDE THE QUOTES# 
```
So, now you should be ready to roll. Just start the jupyterhub in your server and login from another computer!

If, after starting the server and successfully login in, the container fails to start, sometimes it is because there are hanging containers.
To clear them, stop jupyterhub and remove stopped containers by:
```bash
docker rm $(docker ps -aq)
```
Then, restart the jupyterhub server.
