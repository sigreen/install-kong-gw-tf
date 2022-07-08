Installing Kong Gateway with Terraform
===========================================================

This example stands up a simple Azure AKS cluster, then installs Kong Gateway Enterprise on that cluster.  Lastly, it enables BasicAuth RBAC for Kong Manager and Developer Portal.

## Prerequisites
1. AKS Credentials (App ID and Password)
2. Terraform CLI
3. Azure CLI
4. AKS Domain name

## Procedure

1. Open `/tf-provision-aks/aks-cluster.tf` to search & replace `simongreen` with your own name.  That way, all AKS objects will be tagged with your name making them easily searchable. Also, update the Azure region in this file to the region of your choice.
2. If you haven't done so already, create an Active Directory service principal account via the CLI:

 ```bash
 az login
 az ad sp create-for-rbac --skip-assignment`.  # This will give you the `appId` and `password` that Terraform requires to provision AKS.
 ```

3.  In `/tf-provision/aks` directory, create a file called `terraform.tfvars`.  Enter the following text, using your credentials from the previous command:

```bash
appId    = "******"
password = "******"
location = "East US"
```

4. In the root directory, create session configurations. Make sure to change "cookie_domain" in each to your AKS location e.g. `.eastus.cloudapp.azure.com`:

```bash
echo '{"cookie_name":"admin_session","cookie_domain": ".eastus.cloudapp.azure.com","cookie_samesite":"off","secret":"password","cookie_secure":false,"storage":"kong"}' > admin_gui_session_conf

echo '{"cookie_name":"portal_session","cookie_domain": ".eastus.cloudapp.azure.com","cookie_samesite":"off","secret":"password","cookie_secure":false,"storage":"kong"}' > portal_session_conf
```

5. Search and replace 'simongreen' for a unique tag in the `/tf-provision-aks/aks-cluster.tf` file.
6. Via the CLI, `cd tf-provision-aks/` then run the following Terraform commands to provisions AKS:

```bash
terraform init
terraform apply
```

7. Once terraform has stoodup AKS, setup `kubectl` to point to your new AKS instance:

```bash
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)
kubectl get all
```

### NLB Post install:

1. Check services:

`kubectl get svc -n kong -w`

2. You should have somethign similiar to:

```kong-kong-admin            LoadBalancer   10.11.244.9     35.238.46.234    8001:32270/TCP,8444:30125/TCP   3m3s
kong-kong-manager          LoadBalancer   10.11.241.44    34.71.241.10     8002:32319/TCP,8445:30608/TCP   3m3s
kong-kong-portal           LoadBalancer   10.11.241.141   35.222.124.219   8003:31487/TCP,8446:30767/TCP   3m3s
kong-kong-portalapi        LoadBalancer   10.11.246.45    35.239.109.87    8004:30957/TCP,8447:32316/TCP   3m3s
kong-kong-proxy            LoadBalancer   10.11.254.230   35.239.109.90        80:31209/TCP,443:32489/TCP      3m3s
```

3. Let's make sure we can call all these endpoints:

- curl 35.238.46.234:8001
- Got to http://34.71.241.10:8002/overview
- curl 35.222.124.219:8003
- curl 35.239.109.87:8004

4. Via the Azure UI, update each static IP (found in the resource groups) and add a suitable DNS label e.g. `kong-admin` matching 35.238.46.234 for example.

***
