terraform {
    backend "gcs" { 
      bucket  = "terraform-state-infrastructure-extended"
      prefix  = "terraform/state"
    }
}

provider "google" {
  project = "symbolic-datum-416912"
  region  = "europe-west2"
  zone    = "europe-west2-c"
}
