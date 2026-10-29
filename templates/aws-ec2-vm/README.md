# aws-ec2-vm

Creates a VPC with one public subnet, an internet gateway and a route table, then one Amazon Linux 2023 instance in it. The root volume is encrypted gp3, IMDSv2 is required, and the instance has an IAM role with `AmazonSSMManagedInstanceCore` so you can open a shell through Session Manager.

The security group allows no inbound traffic by default. Add CIDR ranges to `allowed_ingress_cidrs` to open SSH (port 22) to them. There is no NAT gateway and no load balancer.

Graviton sizes (`t4g.*`) run arm64 and cost about 20% less than the matching `t3` size; the AMI follows the size you pick.

Needs an AWS cloud connector. Every input has a working default.

**VPC quota.** AWS allows 5 VPCs per region by default. If the deploy fails with "maximum number of VPCs", set `use_default_vpc` to `true` to use the region's default VPC instead, or choose another region.

| Output | Description |
|---|---|
| `instance_id` | ID of the instance |
| `public_ip` | Public IP address of the instance |
| `vpc_id` | ID of the VPC |
| `ssm_connect_command` | `aws ssm start-session` command for the instance |
| `architecture` | `x86_64` or `arm64` |
