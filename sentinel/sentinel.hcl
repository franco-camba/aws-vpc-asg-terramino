policy "restrict-aws-instances-type" {
  enforcement_level = "hard-mandatory"
}

policy "enforce-aws-instance-tags" {
  enforcement_level = "advisory"
}

policy "cost-increment" {
  enforcement_level = "soft-mandatory"
}