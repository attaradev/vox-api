# ECS Module

## Description

Provisions a single AWS ECS cluster using the official Terraform AWS module. To create multiple clusters, instantiate this module multiple times in your root configuration.

## Inputs

- `ecs_cluster_name`: Name of the ECS cluster

## Outputs

- `ecs_cluster_id`: ID of the ECS cluster

## Example Usage

```hcl
module "ecs_1" {
  source           = "./modules/ecs"
  ecs_cluster_name = "example-ecs-cluster-1"
}

module "ecs_2" {
  source           = "./modules/ecs"
  ecs_cluster_name = "example-ecs-cluster-2"
}
```

## Notes

- This module wraps an upstream module and may create supporting resources, but is intended for a single ECS cluster per instantiation.
- For multiple clusters, instantiate the module multiple times as shown above.
- Tag resources for environment and management.
