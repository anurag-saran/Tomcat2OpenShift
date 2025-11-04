#!/bin/bash
################################################################################
# Tomcat to OpenShift Migration - One-Command Demo Installer
# 
# Usage: bash <(curl -sL https://your-url/install.sh)
# Or: chmod +x install.sh && ./install.sh
################################################################################

set -e

DEMO_DIR="$HOME/tomcat-migration-demo"
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}=========================================="
echo "🚀 Tomcat to OpenShift Migration Demo"
echo "   One-Command Installer"
echo -e "==========================================${NC}"
echo ""

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found${NC}"
    echo "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker is not running${NC}"
    echo "Please start Docker Desktop and try again"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 not found${NC}"
    echo "Please install Python 3.8 or higher"
    exit 1
fi

echo -e "${GREEN}✅ Docker found and running${NC}"
echo -e "${GREEN}✅ Python 3 found${NC}"
echo ""

# Create project directory
echo -e "${BLUE}📁 Creating project directory: $DEMO_DIR${NC}"
mkdir -p "$DEMO_DIR"
cd "$DEMO_DIR"

# Clean up any existing setup
echo -e "${BLUE}🧹 Cleaning up any previous installation...${NC}"
docker-compose down 2>/dev/null || true
docker rm -f tomcat-test-vm 2>/dev/null || true
rm -rf sample-apps openshift-output wars-instance-* 2>/dev/null || true

# Create directory structure
echo -e "${BLUE}📂 Creating directory structure...${NC}"
mkdir -p sample-apps/hello-world/WEB-INF/classes/com/example
mkdir -p sample-apps/employee-manager/WEB-INF/classes/com/example

# Create Hello World App
echo -e "${BLUE}📝 Creating Hello World application...${NC}"
cat > sample-apps/hello-world/index.jsp << 'EOF'
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Hello World App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2196F3; }
        .info { background: #e3f2fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Hello World Application</h1>
        <div class="info">
            <p><strong>Current Time:</strong> <%= new java.util.Date() %></p>
            <p><strong>Server Info:</strong> <%= application.getServerInfo() %></p>
            <p><strong>Session ID:</strong> <%= session.getId() %></p>
        </div>
        <hr>
        <p><a href="hello">Test Servlet →</a></p>
    </div>
</body>
</html>
EOF

cat > sample-apps/hello-world/WEB-INF/web.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee 
         http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
         version="4.0">
    <display-name>Hello World Application</display-name>
    <servlet>
        <servlet-name>HelloServlet</servlet-name>
        <servlet-class>com.example.HelloServlet</servlet-class>
    </servlet>
    <servlet-mapping>
        <servlet-name>HelloServlet</servlet-name>
        <url-pattern>/hello</url-pattern>
    </servlet-mapping>
</web-app>
EOF

cat > sample-apps/hello-world/WEB-INF/classes/com/example/HelloServlet.java << 'EOF'
package com.example;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Date;

public class HelloServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        out.println("<!DOCTYPE html>");
        out.println("<html><head>");
        out.println("<style>body{font-family:Arial;margin:50px;background:#f5f5f5;}");
        out.println(".container{background:white;padding:30px;border-radius:10px;}</style>");
        out.println("</head><body><div class='container'>");
        out.println("<h1>✅ Hello from Servlet!</h1>");
        out.println("<p>This is a test servlet running in Tomcat</p>");
        out.println("<p><strong>Request URI:</strong> " + request.getRequestURI() + "</p>");
        out.println("<p><strong>Timestamp:</strong> " + new Date() + "</p>");
        out.println("</div></body></html>");
    }
}
EOF

# Create Employee Manager App
echo -e "${BLUE}📝 Creating Employee Manager application...${NC}"
cat > sample-apps/employee-manager/index.jsp << 'EOF'
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Employee Manager</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; }
        h1 { color: #4CAF50; }
        .button { background: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; 
                  border-radius: 5px; display: inline-block; margin-top: 20px; }
        .button:hover { background: #45a049; }
        .info { background: #e3f2fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>👥 Employee Management System</h1>
        <p>Welcome to the Employee Manager application</p>
        <div class="info">
            <p><strong>Application Status:</strong> Running</p>
            <p><strong>Deployed at:</strong> <%= new java.util.Date() %></p>
            <p><strong>Version:</strong> 1.0.0</p>
        </div>
        <a href="employees" class="button">View All Employees →</a>
    </div>
</body>
</html>
EOF

cat > sample-apps/employee-manager/WEB-INF/web.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee 
         http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
         version="4.0">
    <display-name>Employee Manager</display-name>
    <servlet>
        <servlet-name>EmployeeServlet</servlet-name>
        <servlet-class>com.example.EmployeeServlet</servlet-class>
    </servlet>
    <servlet-mapping>
        <servlet-name>EmployeeServlet</servlet-name>
        <url-pattern>/employees</url-pattern>
    </servlet-mapping>
</web-app>
EOF

cat > sample-apps/employee-manager/WEB-INF/classes/com/example/EmployeeServlet.java << 'EOF'
package com.example;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

public class EmployeeServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        out.println("<!DOCTYPE html><html><head>");
        out.println("<style>");
        out.println("body{font-family:Arial;margin:50px;background:#f5f5f5;}");
        out.println(".container{max-width:800px;margin:0 auto;background:white;padding:30px;border-radius:10px;}");
        out.println("table{width:100%;border-collapse:collapse;margin-top:20px;}");
        out.println("th,td{border:1px solid #ddd;padding:12px;text-align:left;}");
        out.println("th{background-color:#4CAF50;color:white;}");
        out.println("tr:hover{background-color:#f5f5f5;}");
        out.println("</style></head><body><div class='container'>");
        out.println("<h1>👥 Employee List</h1>");
        out.println("<table>");
        out.println("<tr><th>ID</th><th>Name</th><th>Department</th><th>Email</th></tr>");
        out.println("<tr><td>1</td><td>John Doe</td><td>Engineering</td><td>john@example.com</td></tr>");
        out.println("<tr><td>2</td><td>Jane Smith</td><td>Marketing</td><td>jane@example.com</td></tr>");
        out.println("<tr><td>3</td><td>Bob Johnson</td><td>Sales</td><td>bob@example.com</td></tr>");
        out.println("<tr><td>4</td><td>Alice Williams</td><td>HR</td><td>alice@example.com</td></tr>");
        out.println("<tr><td>5</td><td>Charlie Brown</td><td>Finance</td><td>charlie@example.com</td></tr>");
        out.println("</table>");
        out.println("</div></body></html>");
    }
}
EOF

# Create Dockerfile
echo -e "${BLUE}🐳 Creating Dockerfile...${NC}"
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    openjdk-11-jdk \
    openssh-server \
    curl \
    wget \
    vim \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd && \
    echo 'root:password123' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

WORKDIR /opt
RUN wget -q https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.80/bin/apache-tomcat-9.0.80.tar.gz && \
    tar -xzf apache-tomcat-9.0.80.tar.gz && \
    mv apache-tomcat-9.0.80 tomcat-base && \
    rm apache-tomcat-9.0.80.tar.gz

COPY sample-apps /opt/sample-apps
COPY setup_tomcat.sh /opt/setup_tomcat.sh
RUN chmod +x /opt/setup_tomcat.sh

EXPOSE 22 8081 8082

CMD ["/opt/setup_tomcat.sh"]
EOF

# Create Tomcat setup script
cat > setup_tomcat.sh << 'EOF'
#!/bin/bash
/usr/sbin/sshd
cd /opt

# Instance 1 (Port 8081)
cp -r tomcat-base tomcat-instance1
cd tomcat-instance1
sed -i 's/port="8080"/port="8081"/g' conf/server.xml
sed -i 's/port="8005"/port="8015"/g' conf/server.xml
cat > bin/setenv.sh << 'SETENV'
export JAVA_OPTS="-Xms256m -Xmx512m -Djava.awt.headless=true"
export CATALINA_HOME=/opt/tomcat-base
export CATALINA_BASE=/opt/tomcat-instance1
SETENV
chmod +x bin/setenv.sh

cd /opt/sample-apps/hello-world
javac -cp /opt/tomcat-base/lib/servlet-api.jar WEB-INF/classes/com/example/HelloServlet.java
jar -cvf hello-world.war * > /dev/null 2>&1
cp hello-world.war /opt/tomcat-instance1/webapps/

# Instance 2 (Port 8082)
cd /opt
cp -r tomcat-base tomcat-instance2
cd tomcat-instance2
sed -i 's/port="8080"/port="8082"/g' conf/server.xml
sed -i 's/port="8005"/port="8025"/g' conf/server.xml
cat > bin/setenv.sh << 'SETENV'
export JAVA_OPTS="-Xms256m -Xmx768m -Djava.awt.headless=true"
export CATALINA_HOME=/opt/tomcat-base
export CATALINA_BASE=/opt/tomcat-instance2
SETENV
chmod +x bin/setenv.sh

cd /opt/sample-apps/employee-manager
javac -cp /opt/tomcat-base/lib/servlet-api.jar WEB-INF/classes/com/example/EmployeeServlet.java
jar -cvf employee-manager.war * > /dev/null 2>&1
cp employee-manager.war /opt/tomcat-instance2/webapps/

echo "Starting Tomcat instances..."
/opt/tomcat-instance1/bin/catalina.sh start
sleep 5
/opt/tomcat-instance2/bin/catalina.sh start

echo "Tomcat instances started!"
tail -f /opt/tomcat-instance1/logs/catalina.out
EOF

chmod +x setup_tomcat.sh

# Create docker-compose
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  tomcat-vm:
    build: .
    container_name: tomcat-test-vm
    ports:
      - "2222:22"
      - "8081:8081"
      - "8082:8082"
    networks:
      - tomcat-network
networks:
  tomcat-network:
    driver: bridge
EOF

# Build and start Docker
echo ""
echo -e "${BLUE}🔨 Building Docker image (this may take 2-3 minutes)...${NC}"
docker-compose build --quiet

echo ""
echo -e "${BLUE}🚀 Starting Tomcat VM container...${NC}"
docker-compose up -d

echo ""
echo -e "${BLUE}⏳ Waiting for Tomcat to start (45 seconds)...${NC}"
for i in {45..1}; do
    echo -ne "\r   ${i} seconds remaining...   "
    sleep 1
done
echo ""

# Install Python dependencies
echo ""
echo -e "${BLUE}📦 Installing Python dependencies...${NC}"
pip3 install paramiko pyyaml --quiet 2>/dev/null || pip3 install paramiko pyyaml

# Create migration tool (truncated version - see full script below)
echo ""
echo -e "${BLUE}🛠️  Creating migration tool...${NC}"

# Download the full migration script
cat > tomcat_openshift_migration.py << 'PYTHON_EOF'
#!/usr/bin/env python3
"""
Tomcat to OpenShift Migration Tool
Connects to VM, analyzes Tomcat applications, and generates OpenShift deployment files
"""

import paramiko
import json
import os
import re
from pathlib import Path
from typing import List, Dict
import yaml


class TomcatAnalyzer:
    def __init__(self, host: str, username: str, password: str = None, key_file: str = None, port: int = 22):
        """Initialize SSH connection to VM"""
        self.host = host
        self.username = username
        self.port = port
        self.ssh_client = paramiko.SSHClient()
        self.ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        if key_file:
            self.ssh_client.connect(host, port=port, username=username, key_filename=key_file)
        else:
            self.ssh_client.connect(host, port=port, username=username, password=password)
    
    def execute_command(self, command: str) -> tuple:
        """Execute command on remote VM"""
        stdin, stdout, stderr = self.ssh_client.exec_command(command)
        return stdout.read().decode(), stderr.read().decode()
    
    def find_tomcat_processes(self) -> List[Dict]:
        """Find all running Tomcat processes"""
        stdout, stderr = self.execute_command("ps aux | grep '[c]atalina' | grep -v grep")
        
        tomcat_instances = []
        for line in stdout.strip().split('\n'):
            if not line:
                continue
            
            catalina_home = re.search(r'-Dcatalina\.home=([^\s]+)', line)
            catalina_base = re.search(r'-Dcatalina\.base=([^\s]+)', line)
            
            if catalina_home:
                instance = {
                    'catalina_home': catalina_home.group(1),
                    'catalina_base': catalina_base.group(1) if catalina_base else catalina_home.group(1),
                    'process_line': line
                }
                tomcat_instances.append(instance)
        
        return tomcat_instances
    
    def analyze_tomcat_instance(self, instance: Dict) -> Dict:
        """Analyze a specific Tomcat instance"""
        catalina_base = instance['catalina_base']
        
        stdout, _ = self.execute_command(f"ls -1 {catalina_base}/webapps/")
        apps = [app for app in stdout.strip().split('\n') if app and app != 'ROOT']
        
        stdout, _ = self.execute_command(f"cat {instance['catalina_home']}/RELEASE-NOTES 2>/dev/null | grep 'Apache Tomcat Version' | head -1")
        version_match = re.search(r'Version (\d+\.\d+)', stdout)
        tomcat_version = version_match.group(1) if version_match else "9.0"
        
        stdout, _ = self.execute_command(f"cat {catalina_base}/conf/server.xml 2>/dev/null | grep 'Connector port' | head -1")
        port_match = re.search(r'port="(\d+)"', stdout)
        http_port = port_match.group(1) if port_match else "8080"
        
        stdout, _ = self.execute_command(f"cat {catalina_base}/bin/setenv.sh 2>/dev/null")
        jvm_opts = stdout.strip() if stdout.strip() else "-Xmx512m -Xms256m"
        
        memory_match = re.search(r'-Xmx(\d+)([mMgG])', instance['process_line'])
        max_memory = memory_match.group(1) + memory_match.group(2) if memory_match else "512m"
        
        return {
            'catalina_base': catalina_base,
            'catalina_home': instance['catalina_home'],
            'applications': apps,
            'tomcat_version': tomcat_version,
            'http_port': http_port,
            'jvm_opts': jvm_opts,
            'max_memory': max_memory
        }
    
    def download_war_files(self, instance_data: Dict, local_dir: str):
        """Download WAR files from VM to local directory"""
        os.makedirs(local_dir, exist_ok=True)
        
        sftp = self.ssh_client.open_sftp()
        catalina_base = instance_data['catalina_base']
        
        for app in instance_data['applications']:
            war_path = f"{catalina_base}/webapps/{app}"
            
            try:
                sftp.stat(war_path)
                local_path = os.path.join(local_dir, app)
                print(f"  📥 Downloading {war_path}")
                sftp.get(war_path, local_path)
            except IOError:
                print(f"  ⚠️  WAR file not found: {war_path}")
        
        sftp.close()
    
    def close(self):
        """Close SSH connection"""
        self.ssh_client.close()


class OpenShiftGenerator:
    def __init__(self, output_dir: str = "./openshift-output"):
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
    
    def generate_dockerfile(self, app_name: str, tomcat_version: str, jvm_opts: str, wars: List[str]):
        """Generate Dockerfile for Tomcat application"""
        dockerfile_content = f"""FROM tomcat:{tomcat_version}-jdk11-openjdk-slim

# Set JVM options
ENV JAVA_OPTS="{jvm_opts}"

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR files
"""
        for war in wars:
            dockerfile_content += f"COPY {war} /usr/local/tomcat/webapps/{war}\n"
        
        dockerfile_content += """
# Expose port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
"""
        
        app_dir = os.path.join(self.output_dir, app_name)
        os.makedirs(app_dir, exist_ok=True)
        
        with open(os.path.join(app_dir, "Dockerfile"), "w") as f:
            f.write(dockerfile_content)
        
        print(f"  ✅ Generated Dockerfile")
        return dockerfile_content
    
    def generate_imagestream(self, app_name: str):
        """Generate OpenShift ImageStream YAML"""
        imagestream = {
            'apiVersion': 'image.openshift.io/v1',
            'kind': 'ImageStream',
            'metadata': {
                'name': app_name,
                'labels': {
                    'app': app_name,
                    'app.kubernetes.io/name': app_name,
                    'app.kubernetes.io/part-of': 'tomcat-apps'
                }
            },
            'spec': {
                'lookupPolicy': {
                    'local': False
                }
            }
        }
        
        app_dir = os.path.join(self.output_dir, app_name)
        with open(os.path.join(app_dir, "imagestream.yaml"), "w") as f:
            yaml.dump(imagestream, f, default_flow_style=False)
        
        print(f"  ✅ Generated ImageStream")
    
    def generate_buildconfig(self, app_name: str):
        """Generate OpenShift BuildConfig YAML"""
        buildconfig = {
            'apiVersion': 'build.openshift.io/v1',
            'kind': 'BuildConfig',
            'metadata': {
                'name': app_name,
                'labels': {'app': app_name}
            },
            'spec': {
                'output': {
                    'to': {
                        'kind': 'ImageStreamTag',
                        'name': f'{app_name}:latest'
                    }
                },
                'source': {
                    'type': 'Binary',
                    'binary': {}
                },
                'strategy': {
                    'type': 'Docker',
                    'dockerStrategy': {
                        'dockerfilePath': 'Dockerfile'
                    }
                }
            }
        }
        
        app_dir = os.path.join(self.output_dir, app_name)
        with open(os.path.join(app_dir, "buildconfig.yaml"), "w") as f:
            yaml.dump(buildconfig, f, default_flow_style=False)
        
        print(f"  ✅ Generated BuildConfig")
    
    def generate_openshift_deployment(self, app_name: str, port: int, memory: str):
        """Generate OpenShift DeploymentConfig"""
        dc = {
            'apiVersion': 'apps.openshift.io/v1',
            'kind': 'DeploymentConfig',
            'metadata': {
                'name': app_name,
                'labels': {'app': app_name}
            },
            'spec': {
                'replicas': 2,
                'selector': {'app': app_name},
                'template': {
                    'metadata': {'labels': {'app': app_name}},
                    'spec': {
                        'containers': [{
                            'name': app_name,
                            'image': f'{app_name}:latest',
                            'ports': [{'containerPort': port}],
                            'resources': {
                                'limits': {'memory': memory, 'cpu': '500m'},
                                'requests': {'memory': memory, 'cpu': '250m'}
                            }
                        }]
                    }
                },
                'triggers': [
                    {'type': 'ConfigChange'},
                    {'type': 'ImageChange', 'imageChangeParams': {
                        'automatic': True,
                        'containerNames': [app_name],
                        'from': {'kind': 'ImageStreamTag', 'name': f'{app_name}:latest'}
                    }}
                ]
            }
        }
        
        app_dir = os.path.join(self.output_dir, app_name)
        with open(os.path.join(app_dir, "deploymentconfig.yaml"), "w") as f:
            yaml.dump(dc, f, default_flow_style=False)
        
        print(f"  ✅ Generated DeploymentConfig")
    
    def generate_openshift_service(self, app_name: str, port: int):
        """Generate OpenShift Service"""
        service = {
            'apiVersion': 'v1',
            'kind': 'Service',
            'metadata': {'name': app_name, 'labels': {'app': app_name}},
            'spec': {
                'selector': {'app': app_name},
                'ports': [{'port': port, 'targetPort': port}]
            }
        }
        
        app_dir = os.path.join(self.output_dir, app_name)
        with open(os.path.join(app_dir, "service.yaml"), "w") as f:
            yaml.dump(service, f, default_flow_style=False)
        
        print(f"  ✅ Generated Service")
    
    def generate_openshift_route(self, app_name: str, port: int):
        """Generate OpenShift Route"""
        route = {
            'apiVersion': 'route.openshift.io/v1',
            'kind': 'Route',
            'metadata': {'name': app_name, 'labels': {'app': app_name}},
            'spec': {
                'to': {'kind': 'Service', 'name': app_name},
                'port': {'targetPort': port},
                'tls': {'termination': 'edge', 'insecureEdgeTerminationPolicy': 'Redirect'}
            }
        }
        
        app_dir = os.path.join(self.output_dir, app_name)
        with open(os.path.join(app_dir, "route.yaml"), "w") as f:
            yaml.dump(route, f, default_flow_style=False)
        
        print(f"  ✅ Generated Route")
    
    def generate_deploy_script(self, app_name: str):
        """Generate deployment script"""
        script = f"""#!/bin/bash
echo "Deploying {app_name} to OpenShift..."
oc apply -f imagestream.yaml
oc apply -f buildconfig.yaml
oc apply -f deploymentconfig.yaml
oc apply -f service.yaml
oc apply -f route.yaml
echo "Starting build..."
oc start-build {app_name} --from-dir=. --follow
echo "Done! Get route: oc get route {app_name}"
"""
        app_dir = os.path.join(self.output_dir, app_name)
        script_path = os.path.join(app_dir, "deploy.sh")
        with open(script_path, "w") as f:
            f.write(script)
        os.chmod(script_path, 0o755)
        print(f"  ✅ Generated deploy.sh")


def main():
    VM_HOST = "localhost"
    VM_USER = "root"
    VM_PASSWORD = "password123"
    VM_PORT = 2222
    
    print("=" * 60)
    print("🚀 Tomcat to OpenShift Migration Tool")
    print("=" * 60)
    
    try:
        print(f"\n1️⃣  Connecting to VM: {VM_HOST}:{VM_PORT}")
        analyzer = TomcatAnalyzer(VM_HOST, VM_USER, password=VM_PASSWORD, port=VM_PORT)
        print("  ✅ Connected")
        
        print("\n2️⃣  Finding Tomcat processes...")
        tomcat_instances = analyzer.find_tomcat_processes()
        print(f"  ✅ Found {len(tomcat_instances)} Tomcat instance(s)")
        
        ocp_gen = OpenShiftGenerator()
        
        for idx, instance in enumerate(tomcat_instances, 1):
            print(f"\n3️⃣  Analyzing Tomcat instance {idx}...")
            instance_data = analyzer.analyze_tomcat_instance(instance)
            
            print(f"  📊 Tomcat Version: {instance_data['tomcat_version']}")
            print(f"  🔌 Port: {instance_data['http_port']}")
            print(f"  📦 Applications: {', '.join(instance_data['applications'])}")
            
            print(f"\n4️⃣  Downloading WAR files...")
            local_wars_dir = f"./wars-instance-{idx}"
            analyzer.download_war_files(instance_data, local_wars_dir)
            
            for app in instance_data['applications']:
                print(f"\n5️⃣  Generating OpenShift files for: {app}")
                app_name = app.lower().replace('_', '-').replace('.war', '')
                
                ocp_gen.generate_dockerfile(
                    app_name,
                    instance_data['tomcat_version'],
                    instance_data['jvm_opts'],
                    [app]
                )
                
                ocp_gen.generate_imagestream(app_name)
                ocp_gen.generate_buildconfig(app_name)
                ocp_gen.generate_openshift_deployment(
                    app_name,
                    int(instance_data['http_port']),
                    instance_data['max_memory']
                )
                ocp_gen.generate_openshift_service(
                    app_name,
                    int(instance_data['http_port'])
                )
                ocp_gen.generate_openshift_route(
                    app_name,
                    int(instance_data['http_port'])
                )
                ocp_gen.generate_deploy_script(app_name)
        
        print("\n" + "=" * 60)
        print("✅ Migration files generated successfully!")
        print(f"📂 Output directory: {ocp_gen.output_dir}")
        print("=" * 60)
        
        analyzer.close()
        
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
PYTHON_EOF

chmod +x tomcat_openshift_migration.py

# Verify applications are running
echo ""
echo -e "${BLUE}🔍 Verifying Tomcat applications...${NC}"
sleep 5

if curl -s http://localhost:8081/hello-world/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Hello World is running${NC}"
else
    echo -e "${YELLOW}⚠️  Hello World not ready yet (may need more time)${NC}"
fi

if curl -s http://localhost:8082/employee-manager/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Employee Manager is running${NC}"
else
    echo -e "${YELLOW}⚠️  Employee Manager not ready yet (may need more time)${NC}"
fi

# Run the migration tool
echo ""
echo -e "${BLUE}🚀 Running migration tool...${NC}"
echo ""
python3 tomcat_openshift_migration.py

# Final summary
echo ""
echo -e "${BOLD}${GREEN}=========================================="
echo "✅ Demo Setup Complete!"
echo -e "==========================================${NC}"
echo ""
echo -e "${BOLD}📂 Project Location:${NC}"
echo "   $DEMO_DIR"
echo ""
echo -e "${BOLD}🌐 Test Your Applications:${NC}"
echo "   Hello World:      http://localhost:8081/hello-world/"
echo "   Employee Manager: http://localhost:8082/employee-manager/"
echo ""
echo -e "${BOLD}📁 Generated OpenShift Files:${NC}"
echo "   $DEMO_DIR/openshift-output/"
echo ""
echo -e "${BOLD}🔍 View Structure:${NC}"
echo "   cd $DEMO_DIR"
echo "   tree openshift-output/  # or use 'ls -R openshift-output/'"
echo ""
echo -e "${BOLD}🔐 SSH into VM:${NC}"
echo "   ssh root@localhost -p 2222"
echo "   Password: password123"
echo ""
echo -e "${BOLD}📋 Docker Commands:${NC}"
echo "   View logs:    docker logs tomcat-test-vm"
echo "   Stop:         docker-compose down"
echo "   Restart:      docker-compose up -d"
echo ""
echo -e "${BOLD}🧹 Clean Up:${NC}"
echo "   cd $DEMO_DIR && docker-compose down"
echo "   rm -rf $DEMO_DIR"
echo ""
echo -e "${BOLD}📚 Next Steps:${NC}"
echo "   1. Open applications in browser (URLs above)"
echo "   2. Review generated OpenShift manifests"
echo "   3. If you have OpenShift access:"
echo "      cd openshift-output/hello-world"
echo "      ./deploy.sh"
echo ""
echo -e "${GREEN}🎉 Happy migrating!${NC}"
echo ""
