
Warning: Deprecated Parameter

The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile" instead.
Acquiring state lock. This may take a few moments...

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.identity.aws_iam_policy.control_plane_readonly_policy will be created
  + resource "aws_iam_policy" "control_plane_readonly_policy" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + description      = "Solo lectura sobre los recursos que crea este proyecto (VPC/EC2 e IAM)"
      + id               = (known after apply)
      + name             = "control-plane-readonly-policy-dev"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "ec2:DescribeVpcs",
                          + "ec2:DescribeSubnets",
                          + "ec2:DescribeRouteTables",
                          + "ec2:DescribeVpcEndpoints",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                      + Sid      = "ReadOnlyNetwork"
                    },
                  + {
                      + Action   = [
                          + "iam:GetRole",
                          + "iam:GetPolicy",
                          + "iam:GetPolicyVersion",
                          + "iam:ListAttachedRolePolicies",
                        ]
                      + Effect   = "Allow"
                      + Resource = "*"
                      + Sid      = "ReadOnlyIdentity"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # module.identity.aws_iam_policy.data_processing_s3 will be created
  + resource "aws_iam_policy" "data_processing_s3" {
      + arn              = (known after apply)
      + attachment_count = (known after apply)
      + description      = "Permite ListBucket, GetObject y PutObject sobre el prefijo del Data Lake"
      + id               = (known after apply)
      + name             = "data-processing-s3-policy-dev"
      + name_prefix      = (known after apply)
      + path             = "/"
      + policy           = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "s3:ListBucket"
                      + Condition = {
                          + StringLike = {
                              + "s3:prefix" = [
                                  + "raw/*",
                                ]
                            }
                        }
                      + Effect    = "Allow"
                      + Resource  = "arn:aws:s3:::coderhouse-datalake-raw-prueba-semana1"
                      + Sid       = "ListBucketWithPrefix"
                    },
                  + {
                      + Action   = [
                          + "s3:GetObject",
                          + "s3:PutObject",
                        ]
                      + Effect   = "Allow"
                      + Resource = "arn:aws:s3:::coderhouse-datalake-raw-prueba-semana1/raw/*"
                      + Sid      = "GetPutObjectsInPrefix"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id        = (known after apply)
      + tags_all         = (known after apply)
    }

  # module.identity.aws_iam_role.control_plane_readonly will be created
  + resource "aws_iam_role" "control_plane_readonly" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + AWS = "arn:aws:iam::426143721475:user/Mauro"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "control-plane-readonly-role-dev"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "Environment" = "dev"
          + "Name"        = "control-plane-readonly-role-dev"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "Name"        = "control-plane-readonly-role-dev"
        }
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.identity.aws_iam_role.data_processing will be created
  + resource "aws_iam_role" "data_processing" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = [
                              + "://amazonaws.com",
                            ]
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "data-processing-role-dev"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "Environment" = "dev"
          + "Name"        = "data-processing-role-dev"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "Name"        = "data-processing-role-dev"
        }
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # module.identity.aws_iam_role_policy_attachment.control_plane_readonly_attach will be created
  + resource "aws_iam_role_policy_attachment" "control_plane_readonly_attach" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "control-plane-readonly-role-dev"
    }

  # module.identity.aws_iam_role_policy_attachment.data_processing_attach will be created
  + resource "aws_iam_role_policy_attachment" "data_processing_attach" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = "data-processing-role-dev"
    }

  # module.network.aws_route_table.private_a will be created
  + resource "aws_route_table" "private_a" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "Environment" = "dev"
          + "Name"        = "rt-private-a-dev"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "Name"        = "rt-private-a-dev"
        }
      + vpc_id           = (known after apply)
    }

  # module.network.aws_route_table.private_b will be created
  + resource "aws_route_table" "private_b" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "Environment" = "dev"
          + "Name"        = "rt-private-b-dev"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "Name"        = "rt-private-b-dev"
        }
      + vpc_id           = (known after apply)
    }

  # module.network.aws_route_table_association.private_a will be created
  + resource "aws_route_table_association" "private_a" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.network.aws_route_table_association.private_b will be created
  + resource "aws_route_table_association" "private_b" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.network.aws_subnet.private_a will be created
  + resource "aws_subnet" "private_a" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "subnet-private-a-dev"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "subnet-private-a-dev"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.network.aws_subnet.private_b will be created
  + resource "aws_subnet" "private_b" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.0.2.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "subnet-private-b-dev"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Name"        = "subnet-private-b-dev"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.network.aws_vpc.main will be created
  + resource "aws_vpc" "main" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.0.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = true
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Environment" = "dev"
          + "Name"        = "vpc-dev"
        }
      + tags_all                             = {
          + "Environment" = "dev"
          + "Name"        = "vpc-dev"
        }
    }

  # module.network.aws_vpc_endpoint.s3 will be created
  + resource "aws_vpc_endpoint" "s3" {
      + arn                   = (known after apply)
      + cidr_blocks           = (known after apply)
      + dns_entry             = (known after apply)
      + id                    = (known after apply)
      + ip_address_type       = (known after apply)
      + network_interface_ids = (known after apply)
      + owner_id              = (known after apply)
      + policy                = (known after apply)
      + prefix_list_id        = (known after apply)
      + private_dns_enabled   = (known after apply)
      + requester_managed     = (known after apply)
      + route_table_ids       = (known after apply)
      + security_group_ids    = (known after apply)
      + service_name          = "com.amazonaws.us-east-1.s3"
      + service_region        = (known after apply)
      + state                 = (known after apply)
      + subnet_ids            = (known after apply)
      + tags                  = {
          + "Environment" = "dev"
          + "Name"        = "s3-endpoint-dev"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "Name"        = "s3-endpoint-dev"
        }
      + vpc_endpoint_type     = "Gateway"
      + vpc_id                = (known after apply)

      + dns_options (known after apply)

      + subnet_configuration (known after apply)
    }

Plan: 14 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + control_plane_role_arn   = (known after apply)
  + data_processing_role_arn = (known after apply)
  + private_subnet_ids       = [
      + (known after apply),
      + (known after apply),
    ]
  + vpc_id                   = (known after apply)

ÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇÔöÇ

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
