#!/bin/bash

# filepath: /Users/Shared/CODING-SHARED/Ride Sharing App/Development/initialize-rider-app-setup.sh

# Variables
GITHUB_HOST="github.com"
GITHUB_USERNAME="subash1999"
MOBILE_APP_REPOS=("mobile-app-driver" "mobile-app-rider")
LIBRARIES_REPOS=("ride-sharing-app-common")
SERVICES_REPOS=("driver-service" )

NODE_MAJOR_VERSION_REQUIRED=18

# Colors for output
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NC=$(tput sgr0) # No Color

# Initialize results array
results=()
action_results=()
results+=("     |     |     |     ")

#initialize the array to store package name for npm link
NPM_LINK_PACKAGE_NAMES=()

# Function to clone a repository
clone_repo() {
  local repo=$1
  if git clone https://${GITHUB_HOST}/${GITHUB_USERNAME}/${repo}.git; then
    return 0
  else
    return 1
  fi
}

# Function to clone a repository with authentication
clone_repo_with_auth() {
  local repo=$1
  local username=$2
  local token=$3
  if git clone https://${username}:${token}@${GITHUB_HOST}/${GITHUB_USERNAME}/${repo}.git; then
    return 0
  else
    return 1
  fi
}

# Function to handle cloning with retries
handle_cloning() {
  local repos=("$@")
  for repo in "${repos[@]}"; do
    echo "Cloning repository: ${repo}"
    if ! clone_repo ${repo}; then
      echo "Failed to clone repository ${repo} without authentication."
      while true; do
        read -p "Enter your GitHub username: " GITHUB_USERNAME
        read -sp "Enter your GitHub token: " GITHUB_TOKEN
        echo
        if clone_repo_with_auth ${repo} ${GITHUB_USERNAME} ${GITHUB_TOKEN}; then
          break
        else
          echo "Failed to clone repository ${repo} with authentication."
          read -p "Do you want to skip this repository and move to another? (y/n): " choice
          if [ "$choice" == "y" ]; then
            break
          else
            echo "Retrying..."
          fi
        fi
      done
    fi
  done
}

# Function to copy certs folder to service directories
copy_certs_folder() {
  for service in "${SERVICES_REPOS[@]}"; do
    if [ -d "./services/$service" ]; then
      cp -r ./certs "./services/$service/certs"
      echo "Copied certs folder to ./services/$service"
      action_results+=("Copy certs to $service|action status->${GREEN}Success${NC}|NA|NA")
    else
      echo "Service directory ./services/$service does not exist."
      action_results+=("Copy certs to $service|action status->${RED}Failed${NC}|NA|NA")
    fi
  done
}

# Function to copy .serverless folder to service directories
copy_serverless_folder() {
  for service in "${SERVICES_REPOS[@]}"; do
    if [ -d "./services/$service" ]; then
      cp -r ./.serverless "./services/$service/.serverless"
      echo "Copied .serverless folder to ./services/$service"
      action_results+=("Copy .serverless to $service|action status->${GREEN}Success${NC}|NA|NA")
    else
      echo "Service directory ./services/$service does not exist."
      action_results+=("Copy .serverless to $service|action status->${RED}Failed${NC}|NA|NA")
    fi
  done
}

# serve_services_in_new_terminal:
# This function iterates over each service listed in the SERVICES_REPOS array.
# For each service, it:
#   - Constructs the path to the service directory (./services/<service>).
#   - Checks if the directory exists and contains a package.json file.
#   - If valid, uses AppleScript (osascript) to open a new Terminal window, change the directory
#     to the service's folder, and execute "npm run serve" to launch the service.
#   - If the directory or package.json is missing, it outputs a message indicating the service is skipped.
serve_services_in_new_terminal() {
  echo "Launching 'npm run serve' in new Terminal windows for selected services..."
  for service in "${SERVICES_REPOS[@]}"; do
    service_dir="./services/${service}"
    if [ -d "$service_dir" ] && [ -f "$service_dir/package.json" ]; then
      echo "Launching service: ${service}..."
      osascript <<EOF
tell application "Terminal"
    do script "cd $(pwd)/${service_dir} && npm run serve"
    activate
end tell
EOF
    else
      echo "Skipping ${service}: Directory or package.json not found."
    fi
  done
}

# Function to print results
print_results() {
  local results=("$@")
  echo -e "\nResults:"
  printf "%-25s\t%-15s\t%-15s\t%-15s\n" "Repository/Action" "[Cloning/ Install/ Operation Status]" "[.env.developmnet]" "[npm install]"
  for result in "${results[@]}"; do
    IFS='|' read -r repo clone_result env_result npm_result <<< "$result"
    printf "%-25s\t%-30s\t%-30s\t%-15s\n" "$repo" "[$clone_result]" "[$env_result]" "[$npm_result]"
  done
}

# Function to link npm packages from the NPM_LINK_PACKAGE_NAMES array
npm_link_packages() {
  for package in "${NPM_LINK_PACKAGE_NAMES[@]}"; do
    npm link "$package"
  done
}

print_prequisites(){
  echo -e "\nPrerequisites:"
  printf "%-25s\t%-20s\t%-15s\t%-15s\n" "Prerequisite" "Requirement" "Version" "Installation Link"
  prerequisites_array=(
    "Node.js|>= 18.0.0|https://nodejs.org/en/download/"
    "npm|>= 6.0.0|https://nodejs.org/en/download/"
    "git|>= 2.30.0|https://git-scm.com/downloads"
    "Docker|>= 20.0.0|https://docs.docker.com/get-docker/"
    "Docker Compose|>= 1.29.2|https://docs.docker.com/compose/install/"
  )
  for required in "${prerequisites_array[@]}"; do
    IFS='|' read -r name version link <<< "$required"
    printf "%-25s\t%-30s\t%-15s\t%-15s\n" "$name" "${RED}Required and Running${NC}" "$version" "$link"
  done
}

echo "Initializing Rider App Setup..."
echo "This script will help you setup the Rider App development environment."
echo "Please make sure you have the following prerequisites installed:"
print_prequisites
echo "Press enter to continue..."
read -p ""


# Function to check prerequisites
check_prerequisite() {
  local command=$1
  local name=$2
  local url=$3

  if ! command -v $command &> /dev/null; then
    echo "$name is not installed or not in path. Please install $name to continue."
    echo "Download $name from $url"
    echo "Exiting..."
    exit 1
  else
    echo "$name Check: ${GREEN}Success${NC}"
    action_results+=("$name Check|Check Status->${GREEN}Pass${NC}|NA|NA")
  fi
}


perform_prequsites_check() {
  # Check Node.js
  check_prerequisite "node" "Node.js" "https://nodejs.org/en/download/"

  # Check Node.js version
  NODE_VERSION=$(node -v)
  NODE_MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1 | sed 's/[^0-9]*//g')
  if [ $NODE_MAJOR_VERSION -lt $NODE_MAJOR_VERSION_REQUIRED ]; then
    echo "Node version is less than 18. Please install Node.js version 18 or greater to continue."
    echo "Download Node.js from https://nodejs.org/en/download/"
    echo "Exiting..."
    exit 1
  else
    echo "Node Version Check: ${GREEN}Success${NC}"
    action_results+=("Node Version Check|Version Check->${GREEN}Success${NC}|NA|NA")
  fi

  # Check npm
  check_prerequisite "npm" "npm" "https://nodejs.org/en/download/"

  # Check git
  check_prerequisite "git" "git" "https://git-scm.com/downloads"

  # Check Docker
  check_prerequisite "docker" "Docker" "https://docs.docker.com/get-docker/"

  # Check Docker Compose
  check_prerequisite "docker-compose" "Docker Compose" "https://docs.docker.com/compose/install/"

  #awscli check
  check_prerequisite "aws" "AWS CLI" "https://aws.amazon.com/cli/"

  #check if docker is running
  if ! docker info &> /dev/null; then
    echo "Docker is not running. Please start Docker to continue."
    echo "Exiting..."
    exit 1
  else
    echo "Docker Running Check: ${GREEN}Success${NC}"
    action_results+=("Docker Running Check|Running Check->${GREEN}Success${NC}|NA|NA")
  fi
}

# Perform prerequisites check
perform_prequsites_check

# install serverless on the current folder
npm install -g serverless
action_results+=("Serverless Global Installation|Install Check->${GREEN}Success${NC}|NA|NA")

# check the presense of .serverless folder after login
if [ -d ".serverless" ]; then
  echo "Serverless Login Check: ${GREEN}Success${NC}"
  action_results+=("Serverless Login Check|${GREEN}Success${NC}|NA|NA")
else
  # login to serverless
  serverless login
  #wait for user to login to serverless
  read -p "Press enter to continue"
  if [ -d ".serverless" ]; then
    echo "Serverless Login Check: ${GREEN}Success${NC}"
    action_results+=("Serverless Login Check|${GREEN}Success${NC}|NA|NA")
  else
    echo "Serverless Login Check: ${RED}Failed${NC}"
    action_results+=("Serverless Login Check|${RED}Failed${NC}|NA|NA")
    echo "Please login to serverless and run the script again from current directory."
    echo "Exiting..."
    exit 1
  fi
fi
# define action_results array to store the results of each action
action_results=()
#  store the results till now in action_results array
action_results+=("${results[@]}")
# clear the results array
results=()

# add some blank lines in results array to separate the sections
results+=("     |     |     |     ")
results+=("     |     |     |     ")
results+=("     |     |     |     ")
results+=("     |     |     |     ")

# step 1: clone the library repositories
# make library folder
mkdir -p libraries

cd libraries

for repo in "${LIBRARIES_REPOS[@]}"; do
  clone_result="${RED}Failed${NC}"
  env_result="${RED}Not attempted${NC}"
  npm_result="${RED}Not attempted${NC}"

  echo "Cloning repository: ${repo}"
  if clone_repo ${repo}; then
    clone_result="${GREEN}Success${NC}"
  else
    echo "Failed to clone repository ${repo} without authentication."
    while true; do
      read -p "Enter your GitHub username: " GITHUB_USERNAME
      read -sp "Enter your GitHub token: " GITHUB_TOKEN
      echo
      if clone_repo_with_auth ${repo} ${GITHUB_USERNAME} ${GITHUB_TOKEN}; then
        clone_result="${GREEN}Success${NC}"
        break
      else
        echo "Failed to clone repository ${repo} with authentication."
        read -p "Do you want to skip this repository and move to another? (y/n): " choice
        if [ "$choice" == "y" ]; then
          break
        else
          echo "Retrying..."
        fi
      fi
    done
  fi

  if [ -d "${repo}" ]; then
    cd ${repo}
    if npm install; then
      npm_result="${GREEN}Success${NC}"
      npm run build
      if [ -d "../compiled/${repo}" ]; then
        # Navigate to the compiled directory and then return to the original directory using pushd/popd
        pushd "../compiled/${repo}" > /dev/null

        # Retrieve the package name from package.json (assumes it's quoted on the same line)
        PACKAGE_NAME=$(grep '"name":' package.json | sed 's/.*"name": *"\([^"]*\)".*/\1/')

        # Add the package name to the NPM_LINK_PACKAGE_NAMES array
        NPM_LINK_PACKAGE_NAMES+=("$PACKAGE_NAME")

        npm link

        popd > /dev/null        
      else
        echo "Directory ../compiled/${repo} does not exist. Skipping."
      fi
    else
      npm_result="${RED}Failed${NC}"
    fi
    # npm_result="${RED}npm install Not attempted (managed on Dockerfile or Docker Compose)${NC}"
    if cp .env.template .env.development; then
      env_result="${GREEN}Success${NC}"
    else
      env_result="${RED}Failed${NC}"
    fi
    cd ..
  fi

  results+=("${repo}|Clone Res->${clone_result}|Env Copy Res->${env_result}|NPM install res->${npm_result}")
done

cd ..

# Step 2: Clone mobile app repositories
for repo in "${MOBILE_APP_REPOS[@]}"; do
  clone_result="${RED}Failed${NC}"
  env_result="${RED}Not attempted${NC}"
  npm_result="${RED}Not attempted${NC}"
  
  echo "Cloning repository: ${repo}"
  if clone_repo ${repo}; then
    clone_result="${GREEN}Success${NC}"
  else
    echo "Failed to clone repository ${repo} without authentication."
    while true; do
      read -p "Enter your GitHub username: " GITHUB_USERNAME
      read -sp "Enter your GitHub token: " GITHUB_TOKEN
      echo
      if clone_repo_with_auth ${repo} ${GITHUB_USERNAME} ${GITHUB_TOKEN}; then
        clone_result="${GREEN}Success${NC}"
        break
      else
        echo "Failed to clone repository ${repo} with authentication."
        read -p "Do you want to skip this repository and move to another? (y/n): " choice
        if [ "$choice" == "y" ]; then
          break
        else
          echo "Retrying..."
        fi
      fi
    done
  fi

  if [ -d "${repo}" ]; then
    cd ${repo}
    # uncomment the following lines if npm install is required
    npm_link_packages
    npm_result="${RED}npm install Not attempted (managed on Dockerfile or Docker Compose)${NC}"
    if npm install; then
      npm_result="${GREEN}Success${NC}"
      npm_link_packages
    else
      npm_result="${RED}Failed${NC}"
    fi
    if cp .env.template .env.development; then
      env_result="${GREEN}Success${NC}"
    else
      env_result="${RED}Failed${NC}"
    fi
    cd ..
  fi

  results+=("${repo}|Clone Res->${clone_result}|Env Copy Res->${env_result}|NPM install res->${npm_result}")
done

# Step 2: Create services folder
mkdir -p services

# Step 3: Clone services repositories inside services folder
cd services
for repo in "${SERVICES_REPOS[@]}"; do
  clone_result="${RED}Failed${NC}"
  env_result="${RED}Not attempted${NC}"
  npm_result="${RED}Not attempted${NC}"
  
  echo "Cloning repository: ${repo}"
  if clone_repo ${repo}; then
    clone_result="${GREEN}Success${NC}"
  else
    echo "Failed to clone repository ${repo} without authentication."
    while true; do
      read -p "Enter your GitHub username: " GITHUB_USERNAME
      read -sp "Enter your GitHub token: " GITHUB_TOKEN
      echo
      if clone_repo_with_auth ${repo} ${GITHUB_USERNAME} ${GITHUB_TOKEN}; then
        clone_result="${GREEN}Success${NC}"
        break
      else
        echo "Failed to clone repository ${repo} with authentication."
        read -p "Do you want to skip this repository and move to another? (y/n): " choice
        if [ "$choice" == "y" ]; then
          break
        else
          echo "Retrying..."
        fi
      fi
    done
  fi

  if [ -d "${repo}" ]; then
    cd ${repo}
    npm_link_packages
    npm_result="${RED}npm install Not attempted (managed on Dockerfile or Docker Compose)${NC}"
    if npm install; then
      npm_result="${GREEN}Success${NC}"
      npm_link_packages
    else
      npm_result="${RED}Failed${NC}"
    fi
    if cp .env.template .env.development; then
      env_result="${GREEN}Success${NC}"
    else
      env_result="${RED}Failed${NC}"
    fi
    cd ..
  fi

  results+=("${repo}|Clone Res->${clone_result}|Env Copy Res->${env_result}|NPM install res->${npm_result}")
done

cd ..

#step 5: copy .serverless folder to service directories
copy_serverless_folder

# Step 6: Run docker compose in the current script location
# copy .env.template to .env for docker-compose
cp .env.template .env
action_results+=("Copy .env.template to .env|Env Copy Res->${GREEN}Success${NC}|NA|NA")

# run the generate-certs-for-kafka.sh script
./generate-certs-for-kafka.sh

# copy the certs folder to services
copy_certs_folder

# ask user to update the .env file with their credentials and run docker-compose up -d --build command
echo "Setup completed successfully."
echo "************************"
echo "****** IMPORTANT *******"
echo "Please update the .env on root file with your credentials for docker" 
echo "also update the .env files inside projects of services folder with your credentials"
echo "and run the following command to start the services."
echo " "
echo "docker-compose up -d --build"
echo " "
echo "****** END IMPORTANT *******"
echo "************************"

# Ask if the user wants to run all services and Docker apps
read -p "Do you want to run all the services and Docker apps now? [y/N]: " run_docker
if [[ "$run_docker" =~ ^[Yy]$ ]]; then
  echo "Starting Docker services..."
  docker-compose up -d --build
  # Launch services in new Terminal windows
  serve_services_in_new_terminal
else
  echo "Docker services not started. You can run 'docker-compose up -d --build' later."
fi

# combine action_results and results
results=("${action_results[@]}" "${results[@]}")

# Step 6: Print results
print_results "${results[@]}"