output "instance_public_ip" {
  value = aws_instance.web.public_ip

}

output "bucket_name" {
  value = aws_s3_bucket.site_bucket.bucket

}

output "kms_key_id" {

  value = aws_kms_key.s3_key.id


}