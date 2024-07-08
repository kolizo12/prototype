Just run terraform init 
terraform apply

karpenter.tf
karpenterpolicy.tf
main.tf
nodepool.tf

![image](https://github.com/kolizo12/prototype/assets/20117523/6081f084-b1e1-44f9-969d-0c6e5d824c38)

Based on my test nodes are created outside of node group and they will be managed by the karpenter node pools... Since karpenter bypasses the ASG and talks to EC2 API  the aspect of Managed node groups is only referenced in EKS hence karpenter doesnt respect this.

what comes in play here is the node pool 

```
kolizo@KOLAWOLEs-MacBook-Pro-2 prototype % k get po                                      
NAME                       READY   STATUS    RESTARTS   AGE
inflate-75d744d4c6-2pf9m   1/1     Running   0          26m
inflate-75d744d4c6-6tcxl   1/1     Running   0          13m
inflate-75d744d4c6-82ks5   1/1     Running   0          13m
inflate-75d744d4c6-97vcm   1/1     Running   0          26m
inflate-75d744d4c6-9wql2   1/1     Running   0          13m
inflate-75d744d4c6-bsmvq   1/1     Running   0          13m
inflate-75d744d4c6-cghtd   1/1     Running   0          13m
inflate-75d744d4c6-ckqcb   1/1     Running   0          13m
inflate-75d744d4c6-gp5r2   1/1     Running   0          13m
inflate-75d744d4c6-h8kpw   1/1     Running   0          13m
inflate-75d744d4c6-h9wk8   1/1     Running   0          13m
inflate-75d744d4c6-ksps7   1/1     Running   0          13m
inflate-75d744d4c6-ll42d   1/1     Running   0          13m
inflate-75d744d4c6-lwx7t   1/1     Running   0          26m
inflate-75d744d4c6-p8xrv   1/1     Running   0          13m
inflate-75d744d4c6-pgjdg   1/1     Running   0          13m
inflate-75d744d4c6-q4qd2   1/1     Running   0          13m
inflate-75d744d4c6-srr64   1/1     Running   0          13m
```
