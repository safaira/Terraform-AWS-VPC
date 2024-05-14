resources "local_file" "sample" {
    filename = "home/ubuntu/terraform/terraform-local/automated_file.txt"
    content = "This is my first Terraform file."
    }

resources "random_string" "rnd-str"{
 value = 16
 special = true
 override_special = "!@%^&*~<>{}[]()" 
}
