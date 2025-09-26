# ElastiCache Module

## Description

Provisions a single AWS ElastiCache Redis replication group. To create multiple Redis clusters, instantiate this module multiple times in your root configuration.

## Inputs

- `cluster_id`: Redis replication group ID
- `node_type`: Redis node type
- `num_cache_nodes`: Number of Redis nodes
- `subnet_group_name`: Name of the ElastiCache subnet group
- `subnet_ids`: Subnet IDs for Redis
- `security_group_ids`: Security group IDs for Redis

## Outputs

- `elasticache_replication_group_id`: ID of the replication group
- `elasticache_endpoint`: Primary endpoint address
- `elasticache_subnet_group_name`: Subnet group name

## Example Usage

```hcl
module "redis_1" {
  source             = "./modules/elasticache"
  cluster_id         = "redis-cluster-1"
  node_type          = "cache.t3.micro"
  num_cache_nodes    = 1
  subnet_group_name  = "redis-subnet-group-1"
  subnet_ids         = ["subnet-123", "subnet-456"]
  security_group_ids = ["sg-12345678"]
}

module "redis_2" {
  source             = "./modules/elasticache"
  cluster_id         = "redis-cluster-2"
  node_type          = "cache.t3.micro"
  num_cache_nodes    = 2
  subnet_group_name  = "redis-subnet-group-2"
  subnet_ids         = ["subnet-789", "subnet-012"]
  security_group_ids = ["sg-87654321"]
}
```

## Notes

- This module is designed to create a single Redis replication group per instantiation.
- For multiple clusters, instantiate the module multiple times as shown above.
- Encryption is enabled by default.
- For high availability, set `num_cache_nodes` > 1.
- Tag resources for environment and management.
