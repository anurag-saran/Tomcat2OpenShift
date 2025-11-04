# Tomcat to OpenShift Migration - Quick Start

## One-Command Install

### Option 1: Direct Download and Run
```bash
curl -o install.sh https://raw.githubusercontent.com/YOUR_REPO/install.sh && bash install.sh
```

### Option 2: Manual Download
```bash
# 1. Save the script from the artifact as 'install.sh'
# 2. Make it executable and run
chmod +x install.sh
./install.sh
```

### Option 3: Copy-Paste Method

Open Terminal and run:

```bash
# Create directory
mkdir -p ~/tomcat-migration-demo && cd ~/tomcat-migration-demo

# Download the installer script
cat > install.sh << 'INSTALLER_END'
# [PASTE THE ENTIRE SCRIPT FROM THE ARTIFACT HERE]
INSTALLER_END

# Make executable and run
chmod +x install.sh && ./install.sh
```

## What It Does

The installer automatically:
1. ✅ Checks prerequisites (Docker, Python)
2. ✅ Creates 2 sample Tomcat applications
3. ✅ Builds and starts Docker container (simulated VM)
4. ✅ Installs Python dependencies
5. ✅ Runs the migration tool
6. ✅ Generates OpenShift manifests for both apps

**Total time: 3-5 minutes**

## After Installation

### Test the Applications

Open in your browser:
- http://localhost:8081/hello-world/
- http://localhost:8082/employee-manager/

### View Generated Files

```bash
cd ~/tomcat-migration-demo
ls -la openshift-output/

# Structure:
# openshift-output/
# ├── hello-world/
# │   ├── Dockerfile
# │   ├── buildconfig.yaml
# │   ├── deploymentconfig.yaml
# │   ├── imagestream.yaml
# │   ├── route.yaml
# │   ├── service.yaml
# │   └── deploy.sh
# └── employee-manager/
#     ├── [same files]
```

### Explore the Generated Manifests

```bash
cd ~/tomcat-migration-demo/openshift-output/hello-world

# View deployment configuration
cat deploymentconfig.yaml

# View route (external access)
cat route.yaml

# View the Dockerfile
cat Dockerfile
```

### SSH into the Simulated VM

```bash
ssh root@localhost -p 2222
# Password: password123

# Inside the VM
ps aux | grep catalina
ls -la /opt/tomcat-instance1/webapps/
tail -f /opt/tomcat-instance1/logs/catalina.out
```

## Deploy to OpenShift (Optional)

If you have an OpenShift cluster:

```bash
# Login to OpenShift
oc login https://your-openshift-cluster.com

# Create project
oc new-project tomcat-demo

# Deploy an application
cd ~/tomcat-migration-demo/openshift-output/hello-world
./deploy.sh

# Or manually
oc apply -f imagestream.yaml
oc apply -f buildconfig.yaml
oc apply -f deploymentconfig.yaml
oc apply -f service.yaml
oc apply -f route.yaml

# Start build
oc start-build hello-world --from-dir=. --follow

# Get application URL
oc get route hello-world
```

## Useful Commands

### Docker Management
```bash
cd ~/tomcat-migration-demo

# View running containers
docker ps

# View logs
docker logs tomcat-test-vm

# Follow logs
docker logs -f tomcat-test-vm

# Stop everything
docker-compose down

# Restart
docker-compose up -d

# Rebuild from scratch
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Re-run Migration Tool
```bash
cd ~/tomcat-migration-demo

# Clean old output
rm -rf openshift-output/ wars-instance-*

# Run again
python3 tomcat_openshift_migration.py
```

### Check Tomcat Status
```bash
# Check if Tomcat is responding
curl http://localhost:8081/hello-world/
curl http://localhost:8082/employee-manager/

# Pretty print
curl -s http://localhost:8081/hello-world/ | grep -o '<h1>.*</h1>'
```

## Troubleshooting

### Applications not loading?
```bash
# Wait a bit longer (Tomcat can take 60+ seconds)
sleep 30
curl http://localhost:8081/hello-world/

# Check container logs
docker logs tomcat-test-vm | tail -50

# Check if Tomcat processes are running
docker exec tomcat-test-vm ps aux | grep catalina
```

### Docker issues?
```bash
# Restart Docker Desktop
# Then:
cd ~/tomcat-migration-demo
docker-compose down
docker-compose up -d
```

### Python dependency issues?
```bash
# Try with user flag
pip3 install --user paramiko pyyaml

# Or use virtual environment
python3 -m venv venv
source venv/bin/activate
pip install paramiko pyyaml
python3 tomcat_openshift_migration.py
```

### Port conflicts?
```bash
# Check what's using the ports
lsof -i :8081
lsof -i :8082
lsof -i :2222

# Kill processes if needed
kill -9 <PID>

# Or change ports in docker-compose.yml
```

### SSH connection fails?
```bash
# Check if container is running
docker ps | grep tomcat-test-vm

# Check SSH service
docker exec tomcat-test-vm service ssh status

# Try verbose SSH
ssh -v root@localhost -p 2222
```

## Complete Cleanup

```bash
# Stop and remove everything
cd ~/tomcat-migration-demo
docker-compose down

# Remove all files
cd ~
rm -rf tomcat-migration-demo

# Remove Docker images (optional)
docker rmi tomcat-migration-demo_tomcat-vm
```

## What You've Built

✅ **Simulated VM Environment**
- Ubuntu container with SSH access
- 2 Tomcat instances on different ports
- Sample Java web applications

✅ **Migration Tool**
- SSH connection to "VM"
- Tomcat process discovery
- Configuration analysis
- WAR file extraction

✅ **OpenShift Manifests**
- ImageStream (image management)
- BuildConfig (build automation)
- DeploymentConfig (deployment)
- Service (internal networking)
- Route (external HTTPS access)
- Automated deploy scripts

## Architecture

```
┌─────────────────────────────────────────────┐
│  Your Mac                                   │
│                                             │
│  ┌────────────────────────────────────── ┐  │
│  │ Docker Container (Simulated VM)       │  │
│  │                                          │
│  │  ┌────────────────┐  ┌───────────── ┐ │  │
│  │  │ Tomcat Inst 1  │  │ Tomcat Inst 2│ │  │
│  │  │ Port: 8081     │  │ Port: 8082   │ │  │
│  │  │ hello-world    │  │ employee-mgr │ │  │
│  │  └────────────────┘  └───────────── ┘ │  │
│  │                                       │  │
│  │  SSH Server (Port 2222)               │  │
│  └────────────────────────────────────── ┘  │
│                   ↑                         │
│                   │ SSH Connection          │
│                   │                         │
│  ┌────────────────────────────────────┐     │
│  │ Migration Tool (Python)            │     │
│  │ - Connects via SSH                 │     │
│  │ - Analyzes Tomcat                  │     │
│  │ - Downloads WAR files              │     │
│  │ - Generates OpenShift manifests    │     │
│  └────────────────────────────────────┘     │
│                   ↓                         │
│  ┌────────────────────────────────────┐     │
│  │ openshift-output/                  │     │
│  │ ├── hello-world/                   │     │
│  │ │   ├── Dockerfile                 │     │
│  │ │   ├── *.yaml (OpenShift configs) │     │
│  │ │   └── deploy.sh                  │     │
│  │ └── employee-manager/              │     │
│  │     └── [same structure]           │     │
│  └────────────────────────────────────┘     │
└─────────────────────────────────────────────┘
```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Docker logs: `docker logs tomcat-test-vm`
3. Ensure Docker Desktop is running
4. Verify Python 3.8+ is installed

## Next Steps

1. **Explore the generated manifests** - Understand OpenShift configurations
2. **Modify the sample apps** - Add your own servlets or JSPs
3. **Deploy to OpenShift** - If you have cluster access
4. **Customize the tool** - Adapt for your specific environment

---

**Happy Migrating!** 🚀
