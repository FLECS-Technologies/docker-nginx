group "default" {
  targets = ["all"]
}

group "debug" {
  targets = ["nginx-debug", "nginx-openssl-debug"]
}

group "release" {
  targets = ["nginx", "nginx-openssl"]
}

group "openssl" {
  targets = ["nginx-openssl", "nginx-openssl-debug"]
}

group "no-openssl" {
  targets = ["nginx", "nginx-debug"]
}

target "all" {
  name = "nginx${with_openssl.tag_suffix}${build_type.tag_suffix}"
  context = "."
  dockerfile = "docker/Dockerfile"
  matrix = {
    build_type = [
      {
        type = "debug"
        tag_suffix = "-debug"
      },
      {
        type = "release"
        tag_suffix = ""
      }
    ]
    with_openssl = [
      {
        arg = "true"
        tag_suffix = "-openssl"
      },
      {
        arg = "false"
        tag_suffix = ""
      }
    ]
  }
  args = {
    BUILD_TYPE = build_type.type
    WITH_OPENSSL = with_openssl.arg
  }
  platforms = ["linux/amd64", "linux/arm64"]
  tags = ["flecspublic.azurecr.io/docker/nginx:alpine${with_openssl.tag_suffix}${build_type.tag_suffix}"]
}
