# Resume

My online resume to practice AWS and complete the Cloud Resume Challenge

Requirements:

frontend resume html with css as a static website stored in an s3 bucket.
The frontend should communicate with a simple api that stores the count of visits to the website in a dynamodb database.
The entire project should be deployed to AWS with terraform and have an entire ci/cd pipeline through github actions, including testing.


Steps:

1. Setting up the IAM role:
In order to be able to use terraform to deploy and destroy my infra, I want to use github actions. To do so I must enable OIDC connection from github, such that aws allows github actions to assume my role and thus have access to AWS resources. 
I followed this guide to create that role and identity provider: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html#idp_oidc_Create_GitHub
