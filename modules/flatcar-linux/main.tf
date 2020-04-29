data "external" "flatcar_version" {
  program = ["sh", "-c", "curl https://${var.flatcar_channel}.release.flatcar-linux.net/amd64-usr/current/version.txt | sed -n 's/FLATCAR_VERSION=\\(.*\\)$/{\"flatcar_version\": \"\\1\"}/p'"]
}
