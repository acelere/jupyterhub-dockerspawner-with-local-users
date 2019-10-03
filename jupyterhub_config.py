# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os


#from https://github.com/jupyterhub/dockerspawner/issues/172
from dockerspawner import DockerSpawner
class MyDockerSpawner(DockerSpawner):
   def start(self):
      #username is self.user.name
      #THIS DID NOT WORK - error unhashable
      #changed approach >> adding to the volumes dictionary directly below
      self.volumes[ '/srv/jhub_persistent/data/' : '/home/jovyan/data/' ]
      return super().start()


#from: https://github.com/jupyterhub/jupyterhub/blob/master/examples/bootstrap-script/jupyterhub_config.py
def create_dir_hook(spawner):
   username = spawner.user.name
   volume_path = os.path.join('/srv/jhub_persistent/', username)
   if not os.path.exists(volume_path):
      os.mkdir(volume_path, 0o775)
      pass
   pass



c = get_config()


# Spawn single-user servers as Docker containers
c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'

# Prepare the directory for pesistent storage
c.Spawner.pre_spawn_hook = create_dir_hook

# Spawn containers from this image
c.DockerSpawner.image = 'container_44'

# Lab as default, with jupyter-labhub enabled
# IF you want to start with Jupyterlab, uncomment lines below
c.Spawner.default_url = '/lab'
c.Spawner.cmd = ['jupyter-labhub']

notebook_dir = os.environ.get('DOCKER_NOTEBOOK_DIR') or '/home/jovyan/work'
c.DockerSpawner.notebook_dir = notebook_dir

#mount the 2 persistent directories
c.DockerSpawner.volumes = { '/srv/jhub_persistent/{raw_username}': notebook_dir, '/srv/jhub_persistent/data':'/home/jovyan/work/data' }

#had to se the IP otherwise got an error
c.JupyterHub.hub_ip = '192.168.11.112'
