# jupyterhub-dockerspawner-with-local-users
<p> While learning how to implement a JupyterHub server using a dockerspawner, the tutorial available  <a href="https://github.com/jupyterhub/jupyterhub-deploy-docker">here</a> uses OAuthenticator and GitHub OAuth, which means you need a valid IP with DNS entry. </p>
<p> Since I was trying to set up a JHub server inside my organization, and since I do not have an external IP/DNS, I had to figure out how to use the default local linux system authenticator </p>
<p> Therefore, this JupterHub Narrative or Use Case will take you from a fresh Ubuntu install to a functioning <b>JupyterHub server</b> using the <b>default local users authenticator</b>, <b>dockerspawner</b> using a custom container, <b>persistent storage</b> for each user as well as <b>persistent shared storage</b> for the group. </p>
<p> This is a good setup for a small institution: 2-20 users.</p>

