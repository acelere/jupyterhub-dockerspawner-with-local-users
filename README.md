# jupyterhub-dockerspawner-with-local-users
<b> THIS IS A WORK IN PROGRESS </b>
<p> While learning how to implement a JupyterHub server using a dockerspawner, the tutorial available  <a href="https://github.com/jupyterhub/jupyterhub-deploy-docker">here</a> uses OAuthenticator and GitHub OAuth, which means you need a valid IP with DNS entry. </p>
<p> Since I was trying to set up a JHub server inside my organization, and since I do not have an external IP/DNS, I had to figure out how to use the default local linux system authenticator </p>
<p> Therefore, this JupterHub Narrative or Use Case will take you from a fresh Ubuntu install to a functioning <b>JupyterHub server</b> using the <b>default local users authenticator</b>, <b>dockerspawner</b> using a custom container, <b>persistent storage</b> for each user as well as <b>persistent shared storage</b> for the group. </p>
<p> This is a good setup for a small institution: 2-20 users.</p>
<p> In my particular case, the idea is to create a data analysis environment for students, where they will have access to large data files from a flight test aircraft data acquisition system and will be able to use a variety of tools in the form of pre-defined notebooks.</p>
<p>The motivation to use jupyterhub came from the ability to standardize the environment and allow the students to "hit the ground running" instead of battling with software installation. Pretty common scenario for a school, in my case, a small school.</p>
<p>The motivation to use dockerspawner came from the fact that the tools (notebooks) will be quite compute intensive and thus, I needed the ability to spawn independent processes that I could kill (as an administrator) and prepare for future growth by allowing the containers to be spawned in other computers.</p>

<p></p>

## Installation

<p>Start from a fresh ubuntu install. I have used 18.04 on a computer connected to my local network.</p>
<p>To make things easy, after the installation was complete, I went into the router configuration and fixed the IP for that computer, using its MAC address. This is to ensure that when running JupyterHub, the IP address is fixed.</p>
<p> We are assuming root access here </p>
<p>Install the Universe repository:</p>

```bash
add-apt-repository universe
```

<p>Next, install docker as per <a href="https://docs.docker.com/install/linux/docker-ce/ubuntu/#supported-storage-drivers">this link</a></p>
Alternatively, you can install by:

```bash
wget https://get.docker.com
mv index.html getdocker.sh
chmod 755 getdocker.sh
./getdocker.sh 
```
After installing docker, you need to add your user to the docker group to allow for it to start a docker container.
```bash
usermod -aG docker <your user name here> 
```
Next up is to install JupyterHub, as described in the <a href="https://github.com/jupyterhub/jupyterhub/blob/master/README.md">jupyterhub_github</a>. If your Ubuntu Server does not have nodejs installed and the apt install method does not work, you can follow this link with nodejs install instructions: <a href="https://github.com/nodesource/distributions#debinstall">nodejs_install</a>


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
mkdir "$NBDIR"
# make it owned by the GID of the notebook containers.
# This is 100 in the jupyter docker-stacks,
# but should be whatever GID your containers run as
chown :100 "$NBDIR"
# make it group-setgid-writable
chmod g+rws "$NBDIR"
# set the default permissions for new files to group-writable
setfacl -d -m g::rwx "$NBDIR"
```
To enable this persistent directory to be accessed by the docker user, we needed to set permissions and acl (already in the above snippet and as decribed <a href="https://github.com/jupyterhub/dockerspawner/issues/160">here</a>). As minrk explains:

    The s in chmod means that any new files created in that directory, by any user (including root), will be owned by the same group as the parent, which we set to 100.
    The setfacl makes it so that any new files have default permissions including full group access.


At this point, we are now ready to build our container.
Use the dockerfile from this repository, as a starter, and modify it to your needs.
Here is a breakdown of the dockerfile with explanations:

First, start with a fresh python image and install the packages you want. Below is just a snipet and you should look at the Dockerfile that is in this repo:
```
FROM python:3.6.6
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
```
Second, let's create the user "jovyan" and add this user to the "users" group:
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
```RUN mkdir /home/jovyan/work
RUN mkdir /home/jovyan/work/data
RUN chown -R jovyan /home/jovyan/work
```
And last, we tell the container to run the command to start the jupyterhub-singleuser:
```
CMD ["jupyterhub-singleuser"]
```
After putting this dockerfile in your server, it is time to build the container. Run the following from within the same directory you placed the dockerfile in:
```bash
docker build -t <choose_your_docker_container_name> --build-arg JUPYTERHUB_VERSION=0.9.4 . 
```
It is very important to pin the JUPYTERHUB_VERSION, otherwise you get an error later on. You need to use the same version (usually latest) as of your install.

With the docker container built, it is time to make your jupyterhub_config.py file.
Again, you can start with the one in this repo, adjusting the container name to whatever you chose when building it just above.

For Jupyterlab interface, uncomment the line that sets the default URL to '/lab'

Key things for your jupyterhub_config.py file:
As explained <a href=" https://github.com/jupyterhub/jupyterhub/blob/master/examples/bootstrap-script/jupyterhub_config.py">here</a>, we mount the user directory with this bit of code (inside the jupyterhub_config.py file):
```
def create_dir_hook(spawner):
   username = spawner.user.name
   volume_path = os.path.join('/srv/jhub_persistent/', username)
   if not os.path.exists(volume_path):
      os.mkdir(volume_path, 0o755)
      pass
   pass
...
# Prepare the directory for pesistent storage
c.Spawner.pre_spawn_hook = create_dir_hook
```
We choose the container to be spawned here (make sure the name of the container is the same you used to build it):
```
# Spawn containers from this image
c.DockerSpawner.image = 'choose_your_docker_container_name'
```
# Lab as default
# IF you want to start with Jupyterlab, uncomment line below
#c.Spawner.default_url = '/lab'

We mount the persistent directories with:
```
#mount the 2 persistent directories
c.DockerSpawner.volumes = { '/srv/jhub_persistent/{username}': notebook_dir, '/srv/jhub_persistent/data':'/home/jovyan/work/data' }
```
And finally, we need to set the IP of the JupyterHub, otherwise you also get an error:
```
#had to se the IP otherwise got an error
c.JupyterHub.hub_ip = '192.168.11.112' #THIS NUMBER IS JUST AN EXAMPLE; USE THE JHUB'S SERVER IP INSIDE THE QUOTES# 
```
So, now you should be ready to roll. Just start the jupyterhub in your server and login from another computer!
