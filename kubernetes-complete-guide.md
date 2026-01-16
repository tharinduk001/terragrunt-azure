# Complete Kubernetes Getting Started Guide
# Everything you need in one file - copy and use!

=================================
TABLE OF CONTENTS
=================================
1. Introduction & Prerequisites
2. Pods - The Basics
3. ReplicaSets - Self-Healing
4. Deployments - Production Ready
5. Services - Networking
6. Complete Examples
7. Essential kubectl Commands
8. Practice Exercises
9. Troubleshooting Guide

=================================
1. INTRODUCTION & PREREQUISITES
=================================

Prerequisites:
- A Kubernetes cluster (minikube, kind, k3s, or cloud provider)
- kubectl installed and configured
- Basic understanding of containers

Verify your setup:
```bash
kubectl version
kubectl cluster-info
kubectl get nodes
```

=================================
2. PODS - THE BASICS
=================================

A Pod is the smallest deployable unit in Kubernetes.

--- EXAMPLE 1: Simple Pod ---

File: simple-pod.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
    environment: dev
spec:
  containers:
  - name: nginx-container
    image: nginx:1.24
    ports:
    - containerPort: 80
```

Create and manage:
```bash
# Create the pod
kubectl apply -f simple-pod.yaml

# Check status
kubectl get pods
kubectl get pods -o wide

# Detailed information
kubectl describe pod nginx-pod

# View logs
kubectl logs nginx-pod

# Execute command inside pod
kubectl exec -it nginx-pod -- /bin/bash
# Inside pod: curl localhost
# Exit with: exit

# Delete pod
kubectl delete pod nginx-pod
```

--- EXAMPLE 2: Multi-Container Pod ---

File: multi-container-pod.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
  labels:
    app: demo
spec:
  containers:
  - name: nginx
    image: nginx:1.24
    ports:
    - containerPort: 80
  - name: sidecar
    image: busybox
    command: ['sh', '-c', 'while true; do echo "Sidecar running at $(date)"; sleep 30; done']
```

Manage multi-container pod:
```bash
kubectl apply -f multi-container-pod.yaml

# View logs from specific container
kubectl logs multi-container-pod -c nginx
kubectl logs multi-container-pod -c sidecar

# Execute in specific container
kubectl exec -it multi-container-pod -c nginx -- /bin/bash

kubectl delete pod multi-container-pod
```

=================================
3. REPLICASETS - SELF-HEALING
=================================

ReplicaSet ensures a specified number of pod replicas are running.

--- EXAMPLE: ReplicaSet ---

File: nginx-replicaset.yaml
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
      tier: frontend
  template:
    metadata:
      labels:
        app: nginx
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports:
        - containerPort: 80
```

Manage ReplicaSet:
```bash
# Create ReplicaSet
kubectl apply -f nginx-replicaset.yaml

# View ReplicaSets and pods
kubectl get replicaset
kubectl get rs  # shorthand
kubectl get pods --show-labels

# Scale ReplicaSet
kubectl scale rs nginx-replicaset --replicas=5
kubectl get pods

# Test self-healing: delete a pod and watch it recreate
kubectl delete pod <pod-name>
kubectl get pods -w  # watch mode (Ctrl+C to exit)

# Describe ReplicaSet
kubectl describe rs nginx-replicaset

# Delete ReplicaSet (deletes all pods too)
kubectl delete rs nginx-replicaset
```

Important: In production, use Deployments instead of ReplicaSets directly.

=================================
4. DEPLOYMENTS - PRODUCTION READY
=================================

Deployments manage ReplicaSets and provide rolling updates and rollbacks.

--- EXAMPLE 1: Basic Deployment ---

File: basic-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

Basic deployment commands:
```bash
# Create deployment
kubectl apply -f basic-deployment.yaml

# View deployments, replicasets, and pods
kubectl get deployments
kubectl get deploy  # shorthand
kubectl get rs
kubectl get pods

# Scale deployment
kubectl scale deployment nginx-deployment --replicas=5
kubectl get pods

# Update image (rolling update)
kubectl set image deployment/nginx-deployment nginx=nginx:1.25

# Check rollout status
kubectl rollout status deployment/nginx-deployment

# View rollout history
kubectl rollout history deployment/nginx-deployment

# Rollback to previous version
kubectl rollout undo deployment/nginx-deployment

# Rollback to specific revision
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment --to-revision=1

# Describe deployment
kubectl describe deployment nginx-deployment

# Delete deployment
kubectl delete deployment nginx-deployment
```

--- EXAMPLE 2: Advanced Deployment with Health Checks ---

File: advanced-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-deployment
  labels:
    app: webapp
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Max pods above desired count during update
      maxUnavailable: 1  # Max pods unavailable during update
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
        version: v1
    spec:
      containers:
      - name: webapp
        image: nginx:1.24
        ports:
        - containerPort: 80
        env:
        - name: ENVIRONMENT
          value: "production"
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

Health check explanation:
- **livenessProbe**: Restarts container if check fails
- **readinessProbe**: Removes pod from service if check fails

=================================
5. SERVICES - NETWORKING
=================================

Services provide stable networking for pods.

--- TYPE 1: ClusterIP (Internal Access Only) ---

File: clusterip-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-clusterip
  labels:
    app: nginx
spec:
  type: ClusterIP  # Default type
  selector:
    app: nginx
  ports:
  - port: 80        # Service port
    targetPort: 80  # Container port
    protocol: TCP
    name: http
```

Usage:
```bash
# First, create a deployment
kubectl apply -f basic-deployment.yaml

# Create ClusterIP service
kubectl apply -f clusterip-service.yaml

# View service and endpoints
kubectl get svc
kubectl get endpoints nginx-clusterip

# Test from within cluster
kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -O- nginx-clusterip

# Cleanup
kubectl delete svc nginx-clusterip
kubectl delete deployment nginx-deployment
```

--- TYPE 2: NodePort (External Access) ---

File: nodeport-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
  labels:
    app: nginx
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080  # Optional (30000-32767 range)
    protocol: TCP
    name: http
```

Usage:
```bash
# Create deployment and service
kubectl apply -f basic-deployment.yaml
kubectl apply -f nodeport-service.yaml

# Get service details
kubectl get svc nginx-nodeport

# Access the service:
# For minikube:
minikube service nginx-nodeport --url

# For other clusters:
kubectl get nodes -o wide
# Access via http://<node-ip>:30080

# Cleanup
kubectl delete svc nginx-nodeport
kubectl delete deployment nginx-deployment
```

--- TYPE 3: LoadBalancer (Cloud Provider) ---

File: loadbalancer-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
  labels:
    app: nginx
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
```

Note: LoadBalancer type requires a cloud provider (AWS, GCP, Azure) or metallb.

```bash
kubectl apply -f loadbalancer-service.yaml
kubectl get svc nginx-loadbalancer

# Wait for external IP to be assigned
kubectl get svc nginx-loadbalancer -w
```

=================================
6. COMPLETE EXAMPLES
=================================

--- EXAMPLE: Full Application Stack ---

File: complete-app.yaml
```yaml
---
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v1.0
    spec:
      containers:
      - name: nginx
        image: nginx:1.24
        ports:
        - containerPort: 80
        env:
        - name: APP_VERSION
          value: "v1.0"
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 3
---
# Service
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
  labels:
    app: myapp
spec:
  type: NodePort
  selector:
    app: myapp
  ports:
  - name: http
    port: 80
    targetPort: 80
    nodePort: 30200
```

Deploy and manage:
```bash
# Deploy entire stack
kubectl apply -f complete-app.yaml

# Check all resources
kubectl get all

# View service endpoints
kubectl get endpoints myapp-service

# Access application (minikube)
minikube service myapp-service --url

# Scale application
kubectl scale deployment myapp --replicas=5
kubectl get pods

# Update application
kubectl set image deployment/myapp nginx=nginx:1.25
kubectl rollout status deployment/myapp

# Check rollout history
kubectl rollout history deployment/myapp

# Rollback if needed
kubectl rollout undo deployment/myapp

# Cleanup
kubectl delete -f complete-app.yaml
```

--- QUICK START: One-Liner Deployment ---

```bash
# Create deployment
kubectl create deployment hello --image=nginxdemos/hello --replicas=3

# Expose as service
kubectl expose deployment hello --type=NodePort --port=80

# Access service (minikube)
minikube service hello --url

# Scale
kubectl scale deployment hello --replicas=5

# Cleanup
kubectl delete deployment hello
kubectl delete service hello
```

=================================
7. ESSENTIAL KUBECTL COMMANDS
=================================

--- Cluster Info ---
```bash
kubectl cluster-info
kubectl version
kubectl get nodes
kubectl get nodes -o wide
```

--- Working with Pods ---
```bash
# List pods
kubectl get pods
kubectl get pods -o wide
kubectl get pods --all-namespaces
kubectl get pods -A  # shorthand
kubectl get pods --show-labels
kubectl get pods -l app=nginx  # filter by label

# Describe pod (detailed info)
kubectl describe pod <pod-name>

# Logs
kubectl logs <pod-name>
kubectl logs <pod-name> -f  # follow
kubectl logs <pod-name> -c <container-name>  # specific container
kubectl logs <pod-name> --previous  # previous crashed container

# Execute commands
kubectl exec <pod-name> -- ls /
kubectl exec -it <pod-name> -- /bin/bash

# Copy files
kubectl cp <pod-name>:/path/to/file ./local-file
kubectl cp ./local-file <pod-name>:/path/to/file

# Delete pod
kubectl delete pod <pod-name>
kubectl delete pod <pod-name> --grace-period=0 --force  # force delete
```

--- Working with Deployments ---
```bash
# List deployments
kubectl get deployments
kubectl get deploy -o wide

# Create deployment (imperative)
kubectl create deployment nginx --image=nginx:1.24 --replicas=3

# Scale
kubectl scale deployment <name> --replicas=5

# Update image
kubectl set image deployment/<name> <container>=<new-image>

# Rollout commands
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout undo deployment/<name> --to-revision=2
kubectl rollout pause deployment/<name>
kubectl rollout resume deployment/<name>

# Autoscale
kubectl autoscale deployment <name> --min=2 --max=10 --cpu-percent=80

# Delete deployment
kubectl delete deployment <name>
```

--- Working with Services ---
```bash
# List services
kubectl get services
kubectl get svc -o wide

# Create service (imperative)
kubectl expose deployment <name> --type=NodePort --port=80

# Describe service
kubectl describe svc <service-name>

# Get endpoints
kubectl get endpoints
kubectl get endpoints <service-name>

# Delete service
kubectl delete svc <service-name>
```

--- General Commands ---
```bash
# Get all resources
kubectl get all
kubectl get all -A

# Apply/Create resources
kubectl apply -f <file.yaml>
kubectl apply -f <directory>/
kubectl create -f <file.yaml>

# Delete resources
kubectl delete -f <file.yaml>
kubectl delete pod,svc <name>
kubectl delete all --all  # DANGEROUS: deletes everything

# Edit resource
kubectl edit deployment <name>

# Get YAML/JSON output
kubectl get pod <name> -o yaml
kubectl get pod <name> -o json

# Watch resources
kubectl get pods -w

# Port forwarding (local access)
kubectl port-forward pod/<name> 8080:80
kubectl port-forward svc/<name> 8080:80

# Get events
kubectl get events
kubectl get events --sort-by=.metadata.creationTimestamp

# Resource usage (requires metrics-server)
kubectl top nodes
kubectl top pods

# Explain resources
kubectl explain pod
kubectl explain deployment.spec
```

--- Debugging ---
```bash
# Run temporary pod
kubectl run test --image=busybox --rm -it --restart=Never -- /bin/sh

# Debug with ephemeral container (k8s 1.23+)
kubectl debug <pod-name> -it --image=busybox

# Check API resources
kubectl api-resources

# Diff before applying
kubectl diff -f <file.yaml>

# Dry run
kubectl apply -f <file.yaml> --dry-run=client -o yaml
```

=================================
8. PRACTICE EXERCISES
=================================

--- Exercise 1: Create Your First Pod ---

Step 1: Create nginx-pod.yaml with the simple pod example above
Step 2: Apply it
```bash
kubectl apply -f nginx-pod.yaml
kubectl get pods
kubectl describe pod nginx-pod
kubectl logs nginx-pod
kubectl exec -it nginx-pod -- /bin/bash
# Inside pod: curl localhost
exit
kubectl delete pod nginx-pod
```

--- Exercise 2: ReplicaSet Self-Healing ---

Step 1: Create the ReplicaSet
```bash
kubectl apply -f nginx-replicaset.yaml
kubectl get rs
kubectl get pods
```

Step 2: Delete a pod and watch it recreate
```bash
# Note a pod name
kubectl get pods

# Delete one pod
kubectl delete pod <pod-name>

# Watch new pod being created
kubectl get pods -w
```

Step 3: Cleanup
```bash
kubectl delete rs nginx-replicaset
```

--- Exercise 3: Rolling Update ---

Step 1: Create deployment
```bash
kubectl apply -f basic-deployment.yaml
kubectl get deployments
kubectl get pods
```

Step 2: Update to new version
```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.25
kubectl rollout status deployment/nginx-deployment
```

Step 3: Check history and rollback
```bash
kubectl rollout history deployment/nginx-deployment
kubectl rollout undo deployment/nginx-deployment
kubectl rollout status deployment/nginx-deployment
```

Step 4: Cleanup
```bash
kubectl delete deployment nginx-deployment
```

--- Exercise 4: Service Discovery ---

Step 1: Create deployment and service
```bash
kubectl apply -f basic-deployment.yaml
kubectl apply -f clusterip-service.yaml
```

Step 2: Test service
```bash
kubectl get svc
kubectl get endpoints nginx-clusterip

# Test from temporary pod
kubectl run test --image=busybox --rm -it --restart=Never -- wget -O- nginx-clusterip
```

Step 3: Cleanup
```bash
kubectl delete svc nginx-clusterip
kubectl delete deployment nginx-deployment
```

--- Exercise 5: External Access ---

Step 1: Deploy with NodePort
```bash
kubectl apply -f basic-deployment.yaml
kubectl apply -f nodeport-service.yaml
```

Step 2: Access externally
```bash
kubectl get svc nginx-nodeport

# For minikube
minikube service nginx-nodeport --url

# Access the URL in browser or with curl
```

Step 3: Cleanup
```bash
kubectl delete svc nginx-nodeport
kubectl delete deployment nginx-deployment
```

--- Exercise 6: Complete Stack ---

Step 1: Deploy full application
```bash
kubectl apply -f complete-app.yaml
kubectl get all
```

Step 2: Test and scale
```bash
# Get service URL
minikube service myapp-service --url

# Scale
kubectl scale deployment myapp --replicas=5
kubectl get pods
```

Step 3: Update
```bash
kubectl set image deployment/myapp nginx=nginx:1.25
kubectl rollout status deployment/myapp
```

Step 4: Cleanup
```bash
kubectl delete -f complete-app.yaml
```

=================================
9. TROUBLESHOOTING GUIDE
=================================

--- Problem: Pod Stuck in Pending ---

Symptoms: Pod shows "Pending" status

Diagnosis:
```bash
kubectl describe pod <pod-name>
# Look at Events section
```

Common causes:
- Insufficient CPU/memory on nodes
- Volume mounting issues
- Node selector doesn't match any nodes
- Image pull secrets missing

--- Problem: Pod CrashLoopBackOff ---

Symptoms: Pod keeps restarting

Diagnosis:
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl describe pod <pod-name>
```

Common causes:
- Application error/crash
- Wrong command or arguments
- Missing dependencies
- Health check failing too quickly

--- Problem: ImagePullBackOff ---

Symptoms: Cannot pull container image

Diagnosis:
```bash
kubectl describe pod <pod-name>
# Look for image pull errors
```

Common causes:
- Typo in image name
- Image doesn't exist
- No credentials for private registry
- Network issues

--- Problem: Service Not Accessible ---

Symptoms: Cannot access application through service

Diagnosis:
```bash
kubectl get svc <service-name>
kubectl get endpoints <service-name>
kubectl describe svc <service-name>
```

Common causes:
- No endpoints (pods not matching selector)
- Wrong port configuration
- Pods not ready (readiness probe failing)
- Network policy blocking traffic

--- Problem: Deployment Not Updating ---

Symptoms: Rollout stuck or not progressing

Diagnosis:
```bash
kubectl rollout status deployment/<name>
kubectl describe deployment <name>
kubectl get pods
```

Common causes:
- New pods failing health checks
- Insufficient resources
- Image pull errors
- Wrong rolling update strategy

--- General Debugging Workflow ---

1. Check pod status
```bash
kubectl get pods
```

2. Describe the problematic resource
```bash
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>
```

3. Check logs
```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
```

4. Check events
```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

5. Execute commands in pod
```bash
kubectl exec -it <pod-name> -- /bin/bash
```

6. Check service endpoints
```bash
kubectl get endpoints
```

=================================
BEST PRACTICES
=================================

1. Always use Deployments (not Pods or ReplicaSets directly)
2. Set resource requests and limits
3. Implement health checks (liveness and readiness probes)
4. Use labels effectively for organization
5. Version your YAML files in source control
6. Use kubectl apply (not create) for declarative management
7. Test in development before production
8. Use namespaces for resource isolation
9. Never use :latest tag in production
10. Implement proper logging and monitoring

=================================
NEXT STEPS
=================================

After mastering these basics, explore:

1. ConfigMaps and Secrets - Configuration management
2. Persistent Volumes - Data persistence
3. Namespaces - Resource isolation
4. Ingress - HTTP routing
5. StatefulSets - Stateful applications
6. DaemonSets - Node-level workloads
7. Jobs and CronJobs - Batch workloads
8. Helm - Package management
9. Monitoring - Prometheus, Grafana
10. Service Mesh - Istio, Linkerd

=================================
QUICK REFERENCE
=================================

Resource Types:
- Pod (po): Smallest unit
- ReplicaSet (rs): Maintains replica count
- Deployment (deploy): Manages ReplicaSets
- Service (svc): Network abstraction
- Namespace (ns): Resource isolation

Common Flags:
-f <file>      : Specify file
-o yaml/json   : Output format
-w             : Watch
-l key=value   : Label selector
-A             : All namespaces
--dry-run      : Test without creating

Status Values:
- Pending: Waiting to be scheduled
- Running: Pod is running
- Succeeded: All containers terminated successfully
- Failed: At least one container failed
- CrashLoopBackOff: Container keeps crashing
- ImagePullBackOff: Cannot pull image

=================================
END OF GUIDE
=================================

Save this file and refer to it as you practice!
Each section is complete and ready to use.

Good luck with your Kubernetes journey! 🚀
