resource "aws_security_group_rule" "wireguard" {
  count             = var.enable_wireguard ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.k3s.id
  from_port         = var.wireguard_port
  to_port           = var.wireguard_port
  protocol          = "udp"
  cidr_blocks       = var.wireguard_allowed_cidr_blocks
  description       = "WireGuard VPN access"
}
