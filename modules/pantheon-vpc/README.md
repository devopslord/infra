# pantheon_vpc
This is a Terraform module that will create a VPC, Subnets, a NAT GW,
a Internet GW, and route tables. It is very opinionated at the moment
but can be extended later to be more dynamic.

## Usage
```
module "pantheon_vpc" {
  source = "..."

  vpc_cidr_block = "172.16.0.0" # Example CIDR block
}
```

## Inputs
| Name | Type | Description |
| --- | --- | --- |
| vpc_cidr_block | String | The CIDR block to use for the VPC |
| fake_name | String | Fake deciption |

## Outputs
| Name | Description |
| --- | --- |
| vpc_id | The ID for the VPC created |