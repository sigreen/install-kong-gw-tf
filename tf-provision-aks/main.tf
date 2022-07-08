provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
}

resource "kubernetes_namespace" "kong" {
  metadata {
    name = "kong"
  }
  depends_on = [
    azurerm_kubernetes_cluster.default,
  ]
}

resource "kubernetes_secret" "license" {
   metadata {
    name = "kong-enterprise-license"
    namespace = "kong"
   }
   type = "Opaque"
   data = {
        "license" = file("${path.cwd}/../license/license")
      }
}

resource "kubernetes_secret" "superuser-password" {
   metadata {
    name = "kong-enterprise-superuser-password"
    namespace = "kong"
   }
   type = "Opaque"
   data = {
        password = "kong"
      }
}

resource "kubernetes_secret" "kong-session-config" {
   metadata {
    name = "kong-session-config"
    namespace = "kong"
   }
   type = "Opaque"
   data = {
        "admin_gui_session_conf" = file("${path.cwd}/../admin_gui_session_conf")
        "portal_session_conf" = file("${path.cwd}/../portal_session_conf")
      }
}

resource "helm_release" "kong" {
  name              = "kong"
  chart             = "kong/kong"
  namespace         = "kong"
  skip_crds         = true
  dependency_update = true

    values = [
    templatefile("${path.cwd}/../values/values-lb.yml", {})
  ]

    depends_on = [
    kubernetes_namespace.kong
  ]
}

data "kubectl_filename_list" "manifests" {
    pattern = "./../crd/*.yaml"
}

resource "kubectl_manifest" "my_kong_crd_config" {
    count = length(data.kubectl_filename_list.manifests.matches)
    yaml_body = file(element(data.kubectl_filename_list.manifests.matches, count.index))
    override_namespace = "kong"
  depends_on = [
    helm_release.kong
  ]
}