output "namespace" {
  value = kubernetes_namespace_v1.this.metadata[0].name
}

output "frontend_internal_ip" {
  value = try(kubernetes_service_v1.frontend.status[0].load_balancer[0].ingress[0].ip, null)
}
