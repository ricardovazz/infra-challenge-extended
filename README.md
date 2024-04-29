# infra-challenge-extended

# istio
on top of envoy proxy
deploys sidecar container with each pod, intercepts traffic
-support canary deploy, ab testing, etc

# istio with helm
how to get default helm values 

helm search repo istio/base (check version)

helm show values istio/base --version 1.17.1 > helm-defaults/istio-base-default.yaml


# helm
- The helm provider block establishes your identity to your Kubernetes cluster

        provider "helm" {
          kubernetes {
            host                   = "https://${google_container_cluster.primary.endpoint}"
            token                  = data.google_client_config.default.access_token
            cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
          }
        }

- The helm_release resource deploys the nginx Helm chart to your Kubernetes cluster

        resource "helm_release" "example" {
          name  = "my-local-chart"
          chart = "./helm" #assuming we have a helm folder with a values.yaml
        
          depends_on = [
            google_container_cluster.primary
          ]
        }

- or 

            resource "helm_release" "nginx" {
              name       = "nginx"
              repository = "https://charts.bitnami.com/bitnami"
              chart      = "nginx"
            
              values = [
                file("${path.module}/nginx-values.yaml")
              ]
            }

# helm chart/structure

    helm/
      Chart.yaml          # A YAML file containing information about the chart
      LICENSE             # OPTIONAL: A plain text file containing the license for the chart
      README.md           # OPTIONAL: A human-readable README file
      values.yaml         # The default configuration values for this chart
      values.schema.json  # OPTIONAL: A JSON Schema for imposing a structure on the values.yaml file
      charts/             # A directory containing any charts upon which this chart depends.
      crds/               # Custom Resource Definitions
      templates/          # A directory of templates that, when combined with values,
                          # will generate valid Kubernetes manifest files.
      templates/NOTES.txt # OPTIONAL: A plain text file containing short usage notes

https://helm.sh/docs/topics/charts/#the-chartyaml-file


- Helm charts are composed of two primary files: a Chart.yaml file and a values file.


