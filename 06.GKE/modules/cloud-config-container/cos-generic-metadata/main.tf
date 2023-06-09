/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  cloud_config = templatefile(local.template, merge(var.config_variables, {
    boot_commands     = var.boot_commands
    container_args    = var.container_args
    container_image   = var.container_image
    container_name    = var.container_name
    container_volumes = var.container_volumes
    docker_args       = var.docker_args
    files             = local.files
    run_commands      = var.run_commands
    users             = var.users
    authenticate_gcr  = var.authenticate_gcr
    run_as_first_user = var.run_as_first_user
  }))
  files = {
    for path, attrs in var.files : path => {
      content = attrs.content,
      owner   = attrs.owner == null ? var.file_defaults.owner : attrs.owner,
      permissions = (
        attrs.permissions == null
        ? var.file_defaults.permissions
        : attrs.permissions
      )
    }
  }
  template = (
    var.cloud_config == null
    ? "${path.module}/cloud-config.yaml"
    : var.cloud_config
  )
}
