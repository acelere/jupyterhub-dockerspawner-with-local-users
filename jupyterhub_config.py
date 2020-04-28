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
   print("the volume path that I have is: ", volume_path)
   if not os.path.exists(volume_path):
      os.mkdir(volume_path, 0o775)
      print("created folder because it did not exist...")
      pass
   pass



c = get_config()


# Spawn single-user servers as Docker containers
c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'

# Prepare the directory for pesistent storage
c.Spawner.pre_spawn_hook = create_dir_hook

# Spawn containers from this image
c.DockerSpawner.image = 'c_56'

# Lab as default
# IF you want to start with Jupyterlab, uncomment line below
c.Spawner.default_url = '/lab'



work_dir = os.environ.get('DOCKER_NOTEBOOK_DIR') or '/home/jovyan/work'
notebook_dir = os.environ.get('DOCKER_NOTEBOOK_DIR') or '/home/jovyan'
c.DockerSpawner.notebook_dir = notebook_dir

#mount the 2 persistent directories
#c.DockerSpawner.volumes = { '/srv/jhub_persistent/{username}': work_dir, '/srv/jhub_persistent/data':'/home/jovyan/work/data' }
print("the work dir is: ", work_dir)
print("the dockerspawner volumes are: ", c.DockerSpawner.volumes)
#if the directory being created starts to get weird names, use comment above and use below.
c.DockerSpawner.volumes = { '/srv/jhub_persistent/{raw_username}': work_dir, '/srv/jhub_persistent/data':'/home/jovyan/work/data'}

#had to se the IP otherwise got an error
c.JupyterHub.hub_ip = '192.168.2.4'

#LDAP Authentication
# for LDAP authentication, uncomment all lines below. 
# set the IP address of your LDAP server...
#c.LDAPAuthenticator.bind_dn_template = [
#    "{username}@itps.local"
#    ]
#c.LDAPAuthenticator.server_address = '192.168.2.2'
#c.LDAPAuthenticator.user_attribute = 'sAMAccountName'
#c.LDAPAuthenticator.escape_userdn = False
#c.LDAPAuthenticator.valid_username_regex = '^[a-zA-Z][.a-zA-Z0-9_-]*$'
#c.JupyterHub.authenticator_class = 'ldapauthenticator.LDAPAuthenticator'

