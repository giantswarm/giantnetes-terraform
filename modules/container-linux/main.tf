data "external" "coreos_version" {
  program = ["sh", "-c", "curl https://${var.coreos_channel}.release.core-os.net/amd64-usr/current/version.txt | sed -n 's/COREOS_VERSION=\\(.*\\)$/{\"coreos_version\": \"\\1\"}/p'"]
}
