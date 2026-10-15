environment = "staging"
zone        = "joshuel.com.br"
regions     = ["us-east-1"] # one region: proxied CNAME to the ALB

records = {
  "hello-stg" = {}
}
