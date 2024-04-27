provider "google" {
  project = "symbolic-datum-416912"
  region  = "europe-west2"
  zone    = "europe-west2-c"
  credentials = file("/Users/rdvz/gcp-sandbox/symbolic-datum-416912-2d21e09abfc3.json")
}