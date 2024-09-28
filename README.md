
## Automating Bitbucket pipelines self-hosted runners in AWS

![Photo by Pixabay](https://cdn-images-1.medium.com/max/14394/1*Mr5yyYUmVY1UYzaGvDof6g.jpeg)

Bitbucket pipelines allows you to run your tasks directly in containers as docker-in-docker, so you can leverage containers from trusted sources like open source official container images.

It is very easy and fast to configure.

Perhaps is not as flexible as its competitors GitLab, Azure DevOps, Github Actions etc.

But if you are already using Atlassian tools, it will put the pipelines very close to the developers. With out-of-the-box integration with Jira software.

It has integration with VS Code, so you see after pushing code the status of the pipeline without leaving the IDE.

To make the solution complete, sooner or later you will need to run pipelines in your own infrastructure with self-hosted runners. Since August 2021 you can do that in Bitbucket cloud pipelines with self-hosted runners.

I am focusing here in docker runners, but new types of runners are being added constantly, Windows runners and Mac are also available. There is an open beta of a Linux shell for high load jobs which improves performance over the default docker runner.

This is the architectural diagram on how to use cheap self-hosted runners in AWS for your CI/CD jobs.

![](https://cdn-images-1.medium.com/max/2102/1*W4UItFALBcdj_I__ibt14A.png)

### Creating the runners in Bitbucket

For these tests I created runners at workspace level, these runners will be available to pipelines in all the repositories of the workspace.

Runners can also be configured at repository level.

In workspace settings, there is a workspace runners section, simply add runners there.

![](https://cdn-images-1.medium.com/max/3664/1*corBc081g5zK13CbnCighA.png)

For docker runners, it will display a docker runcommand that is used to start a runner.

The original command requires a bit of tweaking to run it as a daemon, it is intended to be run interactively.

So I simply add nohupat the start and &at the end, so the process remains on background and remove -it from the docker command we don’t need an interactive terminal here. This same command can be converted to a systemd service easily, I’m not doing that because my runners will be disposable in my case.

 <iframe src="https://medium.com/media/6079d6703e181e62b20919b9ed757668" frameborder=0></iframe>

This command contains secrets, so we require a secure place to store it.

So we save these commands in SSM parameter store as a secure string, one per runner in this case.

![](https://cdn-images-1.medium.com/max/5060/1*Qcpyw8extmy-RibfN-E8hQ.png)
>  This is the only manual part in this process, there is no api for bitbucker runners at this time.
>  This issue request could use some up votes :-)
>  [[BCLOUD-21309] Have public API endpoints for pipelines runners — Create and track feature requests for Atlassian products.](https://jira.atlassian.com/browse/BCLOUD-21309)

### AWS [Spot fleet](http://ssm_access_for_instances)

Spot fleet provides you with a way to run groups of spot instances with some rules and maintain that capacity from multiple instance pools and AZs.

Optionally, you can run on-demand spot mixed capacity for stateless critical apps.

In this case, I am using only spot with diversifiedas the fleet allocation strategy, I want to minimize the interruptions. So If I distribute my load between instance families and availability zones, the probabilities of the whole fleet being interrupted should go down.

The spot fleet will make sure of maintaining fleet_type="mantain”the capacity from availability zones and instances families available.

 <iframe src="https://medium.com/media/d47d3e291540765d574af97a04bd13f9" frameborder=0></iframe>

### AWS Parameter Store

[As I showed before](#8149), the configuration of the Bitbucket runners is stored in SSM parameter store as a secure string encrypted with a customer key.

This secures the communication of the keys to register as a runner in Bitbucket pipelines.

### Terraform template files for user data.

With a bit of Ansible help, to prepare the instances to run docker in a vanilla Redhat machine using [this](https://galaxy.ansible.com/geerlingguy/docker) awesome Ansible role.

I’m calling the role directly with some extra-vars and -m include_role.

The complete userdata.sh template looks like this:

 <iframe src="https://medium.com/media/fef68e5648f16b5ca1efc0b3e3b93f48" frameborder=0></iframe>

### The Bitbucket pipeline

With public Bitbucket runners, we can create the self-hosted runners executing terraform.

Here is a very simple custom pipeline where you can pass an action variable to execute the terraform command plan, apply, destroy.
>  It assumes you can access your AWS account from Bitbucket pipelines, you should have at least your AWS keys as repository variables.

 <iframe src="https://medium.com/media/b13676e882a34e962acd01c00b9c5ff7" frameborder=0></iframe>

You can execute by run pipeline, select custom and pass the action to execute.

![](https://cdn-images-1.medium.com/max/2508/1*LPwXHL4HAt8dv6wiv39iuQ.png)

After running the pipeline you should see your runners registered and start using them.

![](https://cdn-images-1.medium.com/max/2000/1*9llcPBCCgh_hZym2paz4vQ.png)

Then adding runs-on your tasks and a label that you added in the runners the tasks will run in your infrastructure.

 <iframe src="https://medium.com/media/52646649b106ada96ae20542b0de329a" frameborder=0></iframe>

[Finally this is the GitHub repo with the complete solution.](https://github.com/agrana/bb-runners-spot-fleet)

