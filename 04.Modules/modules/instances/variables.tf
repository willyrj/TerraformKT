variable project_id {
    type = string
}
variable zone {
    type = string
}
variable region {
    type = string
}

variable name {
    type = string
}
variable machine_type {
    type = string
}
variable image {
    type = string
}
variable network {
    type = string
    default= "default"
}
variable metadata_startup_script {
    type = string
    default= <<-EOT
        #!/bin/bash
    EOT
}
variable allow_stopping_for_update {
    type = string
    default= "true"
}
