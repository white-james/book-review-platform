#######             Application Resources              #######
##############################################################

# Generate a random suffix for unique naming
resource "random_string" "unique_suffix" {
  length  = 6
  special = false
  upper   = false
}
