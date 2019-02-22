# Installing on a Linux Machine
## Install Docker:
1. `sudo yum update -y`
2. `sudo yum install -y docker`

## Install Docker-compose (https://docs.docker.com/compose/install/)
1. `sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose`
2. `sudo chmod +x /usr/local/bin/docker-compose`

## Give Docker Admin Privileges
1. `sudo usermod -aG docker ec2-user`
2. Reboot the machine

## Initialize the docker containers
1. Start docker: `sudo service docker start`
2. Copy the docker-compose.yml file to your machine
3. From the director that docker-compose.yml is located in, run: `docker-compose up`