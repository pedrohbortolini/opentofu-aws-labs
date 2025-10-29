output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets_ids" {
  value = module.vpc.public_subnets_ids
}

output "private_subnets_ids" {
  value = module.vpc.private_subnets_ids
}

output "alb_dns" {
  value = aws_lb.app.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.appdb.address
}

output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "asg_name" {
  value = aws_autoscaling_group.app_asg.name
}