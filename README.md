## Getting started with Drone CI

This repository aims to show how to build a continuos integration process using Drone CI. To get a full picture we recommend to read our [blog post](https://) first. In blog post we describe how we do continuos integration at Maqpie and talk about why enjoy Drone CI so much.

Where to start?

1. If you already have running instance of Drone CI you can just fork this repository and enable it in Drone.
2. If you are not familiar with Drone CI - we have detailed steps on how to setup Drone CI for local & production environments [in this repository](https://github.com/maqpie/deploy-drone)


### Repository structure

The repository represent a typical Node.JS project, which has three services:

1. Landing - a landing site
2. Web - a simple frontend that serves client side assets for React application and do some server side rendering.
3. Api - a restful api.
4. `./deploy` directory has [Ansible](https://www.ansible.com/) deployment scripts which publish built docker containers to the Ubuntu 16.04 and configure Nginx for the application.
5. `.drone.yml` - deployment steps for Drone CI

### Continuous integration steps

1. Every commit to github Pull Request triggers a build which run tests and notify about success/failure using Slack.
2. Every commit to the `master` branch builds all docker containers, publish them to the Dockerhub, run Ansible scripts to deploy application to pre-production or staging environment and notify about success or failures.
3. Every commit to the `production` branch builds all docker containers, publish them to the Dockerhub, run Ansible scripts to deploy application to production environment and notify about success or failures.


## Work with Drone CI

### Install the Drone CLI

The [drone command line tools](http://readme.drone.io/0.5/install/cli/) are used to interact with the drone server from the command line, and provide important utilities for managing users and repository settings.

### Connect to your Drone CI

To connect to your Drone you need to export following variables in terminal:

1. `export DRONE_SERVER=http://138.197.86.232` - this is url of your Drone installation
2. `export DRONE_TOKEN=` - this is your personal authentication token, that can be found in Drone UI at `https://MY_DRONE_URL/account` page. Just click on `SHOW TOKEN` and copy it from there

Now, you should be able to interact with Drone CI using Drone CLI.  


### Drone Plugins

Plugins is a Drone way to integrate with a third party services, such as Amazon S3, Dockerhub and Slack. The full list of currently available plugins can be found [here](http://addons.drone.io/). Plugin is a docker container that execute a predefined task.
In this sample project we use two plugins to achieve what we need:

1. Dockerhub plugin to push our docker images
2. Slack plugin to notify about build status

### Build private variables or secrets

Drone has really nice way of sharing secret information, such as password and ssh keys in a secure way. We use Dockerhub to publish docker images, which require username and password. We also use Ansible to deploy our application over to the production server. To being able to do this we need supply our ssh key. Pushing secret information to the Github repository is a bad practice, creating one possibility for hackers to shut down your service.

Let's start from adding our ssh key:

```
drone global secret add SSH_KEY @/Users/andrew/.ssh/id_rsa-drone-demo
```

Now our ssh key should be available to Drone. The last step remaining is to add our Dockerhub credentials:

```
drone global secret add DOCKER_USERNAME YOUR_DOCKERHUB_USERNAME
drone global secret add DOCKER_PASSWORD YOUR_DOCKERHUB_PASSWORD
drone global secret add DOCKER_EMAIL YOUR_DOCKERHUB_EMAIL
```

Now this variables can be directly used in `.drone.yml`. Here are small example, where we pass Dockerhub credentials to the Drone's Docker plugin:

```
publish-api-docker:
  image: plugins/docker:1.12
  username: ${DOCKER_USERNAME}
  password: ${DOCKER_PASSWORD}
  email: ${DOCKER_EMAIL}
```

### Understanding Drone signature

Drone signature is a simple string the typically resides near your `.drone.yml` as `.drone.yml.sig` and generated using your access token from Drone UI.

Here is how signature works:

1. Everytime you do a change to the `.drone.yml` you need to re-generate a signature.
2. Drone CI than verifies your signature before starting a build and exposes your secrets only in case if verification passed.

There is one possible scenario, where hacker might be able to get access to your keys. If you shell scripts as a command in `.drone.yml` hacker can possibly change this shell script and, for example, make a post request with your ssh key to some endpoint. General security measures is always a good thing to do anyways.

### Generating drone signature

As mentioned above, every time when you do some changes to your `.drone.yml` file - you need to regenerate signature. You can do it using following command:

```
drone sign maqpie/drone-starter
```

Use your repository name as parameter for the `drone sign`.

Note: `docker sign` command will silently fail and won't create a `.docker.yml.sig` file if repository is not enabled using Drone UI.
