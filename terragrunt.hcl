terraform {
  extra_arguments "common_var" {
    commands = [
      "apply",
      "plan",
      "console",
      "import",
      "push",
      "refresh",
      "destroy",
    ]

    arguments = [
      "-var-file=${get_terragrunt_dir()}/environment/us-east.tfvars",
    ]
  }
}
