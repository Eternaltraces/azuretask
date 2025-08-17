Prerequisites for this task to work:

Azure account
Azure DevOps account
Public parallelity from Microsoft given OR self hosted agent.
For self-hosted agent - installed SSH, Ansible, Terraform, Python

In Azure:

Service Principal (App registration with client secret, in more prod solution it can be federated)
Azure Blob Storage to secure tfstate file
Self-hosted agent if in use (was in my case)

In AzureDevOps:

Service Connection based on Service Principal
Dedicated Pool with self-hosted agent
Variable group containing all Service Principal data for Terraform
Secret file containing private SSH key for ansible to connect


All names and files, specifically for:
    - terraform backend (azure blob) name
    - Service principal data
    - Secret file containing private key

Are specific for my use and needs to be changed if run from different environment