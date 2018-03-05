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

<p>Start from a fresh ubuntu install. In my case, I used 16.04 on a computer connected to my local network.</p>
<p>To make things easy, after the installation was complete, I went into the router configuration and fixed the IP for that computer, using its MAC address. This is to ensure that when running JupyterHub, the IP address is fixed</p>
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
Next up is to install JupyterHub, as described in the <a> href="https://github.com/jupyterhub/jupyterhub/blob/master/README.md">jupyterhub github</a>

Let's now create the persistent storage areas, since each docker container will be spawned "new" each time. In my case, I wanted a storage area for each user and a common area to allow for big data files exchange.

If you plan to run notebook servers locally, you will need to install the
[Jupyter notebook](https://jupyter.readthedocs.io/en/latest/install.html)
package:
