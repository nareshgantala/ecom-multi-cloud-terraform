output "frontend_instance_group" {
  value = try(google_compute_region_instance_group_manager.frontend_igm-sr[0].instance_group, null)
}


output "app_instance_group" {
  value = try(google_compute_region_instance_group_manager.app_igm-sr[0].instance_group, null)
}

