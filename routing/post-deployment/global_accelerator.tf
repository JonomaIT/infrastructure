# Global Accelerator: two static anycast IPs in front of both regions. Each region's endpoint is
# the internal NLB of the ecs stack (found through SSM). The traffic dial of each endpoint group
# decides how much traffic each region gets: 100/0 = active-passive, 50/50 = active-active.
#
# Client IP preservation is mandatory for internal NLB endpoints: Global Accelerator delivers the
# traffic with the original client IP, which is why the NLB security group accepts any source.
resource "aws_globalaccelerator_accelerator" "main" {
  name            = var.project_name
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "main" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  protocol        = "TCP"
  client_affinity = "NONE"

  # HTTPS only. Plain HTTP is redirected at the Cloudflare edge and never reaches the origin.
  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn            = aws_globalaccelerator_listener.main.id
  endpoint_group_region   = var.region_primary
  traffic_dial_percentage = var.routing.primary

  endpoint_configuration {
    endpoint_id                    = data.aws_ssm_parameter.primary.value
    weight                         = 100
    client_ip_preservation_enabled = true
  }
}

resource "aws_globalaccelerator_endpoint_group" "secondary" {
  listener_arn            = aws_globalaccelerator_listener.main.id
  endpoint_group_region   = var.region_secondary
  traffic_dial_percentage = var.routing.secondary

  endpoint_configuration {
    endpoint_id                    = data.aws_ssm_parameter.secondary.value
    weight                         = 100
    client_ip_preservation_enabled = true
  }
}
