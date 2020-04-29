variable "aws_region" {
  type        = string
  description = "AWS Region used to differentiate with AWS China where image version is pulled from a different location."
}


variable "flatcar_channel" {
  type = string

  description = <<EOF
The Flatcar Linux update channel.

Examples: `stable`, `beta`, `alpha`
EOF
}

variable "flatcar_version" {
  type = string

  description = <<EOF
The Flatcar Linux version to use. Set to `latest` to select the latest available version for the selected update channel.

Examples: `latest`, `1465.6.0`
EOF
}
