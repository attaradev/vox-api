terraform {
  backend "s3" {
    bucket               = "vox-api-terraform-state"
    key                  = "terraform.tfstate"
    workspace_key_prefix = "envs"
    region               = "us-east-1"
    use_lockfile         = true
    encrypt              = true
  }
}
