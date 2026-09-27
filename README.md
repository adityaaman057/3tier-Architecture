
          # AWS 3-Tier Architecture with Terraform

          This project provisions a small three-tier application stack in AWS:

          1. **Network tier**: A VPC spanning the available Availability Zones, with public, private, and database subnets.
          2. **Application tier**: An internet-facing Application Load Balancer forwards HTTP traffic to web servers in a private Auto Scaling group.
          3. **Database tier**: A private MySQL 8.0 RDS instance is accessible only from the web-server security group.

          The web servers are bootstrapped with cloud-init. They download the latest release of the sample `vanilla-webserver` application and start it on port 8080. The load balancer listens on port 80.

          ## Architecture

          ```text
          Internet
            |
            v
          Public subnets: Application Load Balancer :80
            |
            v
          Private subnets: EC2 Auto Scaling Group :8080
            |
            v
          Database subnets: RDS MySQL 8.0 :3306
          ```

          Security groups enforce the traffic path:

          - Load balancer: HTTP/80 from `0.0.0.0/0`.
          - Web servers: HTTP/8080 from the load balancer; SSH/22 from the VPC CIDR.
          - Database: MySQL/3306 from the web-server security group only.

          The networking module also creates a database subnet group, enables NAT gateways, and uses a single NAT gateway for the private subnets.

          ## Resources

          - VPC module `terraform-aws-modules/vpc/aws` version `2.64.0`.
          - Public, private, and database subnets using the `10.0.0.0/16` VPC CIDR.
          - Application Load Balancer using `terraform-aws-modules/alb/aws` version `5.x`.
          - EC2 launch template using the latest Canonical Ubuntu 24.04 AMD64 AMI.
          - Auto Scaling group with 1 to 3 instances in private subnets.
          - MySQL 8.0 RDS instance using a generated 16-character password.
          - IAM instance profile with permissions requested by the application module.

          ## Prerequisites

          - An AWS account and credentials configured for the AWS CLI or Terraform.
          - Terraform `>= 0.15`.
          - Permission to create VPC, EC2, ELB, IAM, RDS, and related resources.
          - An AWS region with Ubuntu 24.04 AMIs available.
          - A locally available EC2 key pair if SSH access is required.

          The AWS and Cloud Init provider constraints are defined in `versions.tf`. The checked-in `.terraform.lock.hcl`, when present, should be retained for reproducible provider selections.

          ## Configuration

          The sample `terraform.tfvars` contains:

          ```hcl
          namespace = "my-3-tier-architecture"
          region    = "us-west-2"
          ```

          The available root variables are:

          | Variable | Required | Default | Description |
          | --- | --- | --- | --- |
          | `namespace` | Yes | None | Prefix used for resource names. |
          | `region` | No | `us-east-1` | AWS region for deployment. |
          | `ssh_keypair` | No | `null` | Existing EC2 key-pair name for the launch template. |

          To use an EC2 key pair, add it to `terraform.tfvars`:

          ```hcl
          ssh_keypair = "your-existing-keypair-name"
          ```

          Do not commit credentials or generated database passwords. Terraform stores the RDS password in state, so protect the state file and use a remote, encrypted backend for shared or production deployments.

          ## Deploy

          Run these commands from the repository root:

          ```bash
          terraform init
          terraform fmt -recursive
          terraform validate
          terraform plan
          terraform apply
          ```

          After applying, retrieve the public load balancer address:

          ```bash
          terraform output lb_dns_name
          ```

          Open the returned DNS name in a browser or test it with `curl`:

          ```bash
          curl http://$(terraform output -raw lb_dns_name)
          ```

          The generated database password is marked sensitive. To display it explicitly:

          ```bash
          terraform output -raw db_password
          ```

          ## Destroy

          This configuration sets `skip_final_snapshot = true` for the RDS instance. Destroying the stack therefore deletes the database without creating a final snapshot:

          ```bash
          terraform destroy
          ```

          Use a final snapshot and a protected remote state backend before using this configuration for production workloads.

          ## Module layout

          ```text
          .
          |-- main.tf                 Root module composition
          |-- providers.tf            AWS provider configuration
          |-- variables.tf            Root input variables
          |-- outputs.tf              Load balancer DNS and database password
          |-- terraform.tfvars        Sample deployment values
          |-- modules/
             |-- networking/         VPC, subnets, NAT, and security groups
             |-- database/           Password generation and MySQL RDS
             |-- autoscaling/        ALB, launch template, ASG, and cloud-init
          ```

          ## Notes

          - The deployment uses a single NAT gateway to reduce cost; this is a single point of failure for private-subnet egress.
          - The ALB and application listener use plain HTTP. Add HTTPS, an ACM certificate, and a redirect before exposing an application in production.
          - The web-server bootstrap downloads an external GitHub release at instance startup, so private instances need NAT access and the release endpoint must remain available.
          - The default instance classes and storage settings are intentionally small and suitable for a practical or demonstration environment, not production capacity planning.
 