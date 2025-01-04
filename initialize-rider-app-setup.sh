#!/bin/bash

# filepath: /Users/Shared/CODING-SHARED/Ride Sharing App/Development/initialize-rider-app-setup.sh

# Variables
GITHUB_HOST="github.com"
GITHUB_USERNAME="subash1999"
MOBILE_APP_REPOS=("mobile-app-driver" "mobile-app-rider")
SERVICES_REPOS=("driver-service" "rider-service" "google-maps-service" "matching-service" "notification-service")

# Colors for output
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NC=$(tput sgr0) # No Color

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

# Function to print results
print_results() {
  local results=("$@")
  echo -e "\nResults:"
  printf "%-25s\t%-15s\t%-15s\t%-15s\n" "Repository" "[Cloning]" "[].env.local]" "[npm install (managed on Dockerfile or Docker Compose)]"
  for result in "${results[@]}"; do
    IFS='|' read -r repo clone_result env_result npm_result <<< "$result"
    printf "%-25s\t%-15s\t%-15s\t%-15s\n" "$repo" "[$clone_result]" "[$env_result]" "[$npm_result]"
  done
}

# Initialize results array
results=()

# Step 1: Clone mobile app repositories
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
    # if npm install; then
    #   npm_result="${GREEN}Success${NC}"
    # else
    #   npm_result="${RED}Failed${NC}"
    # fi
    npm_result="${RED}npm install Not attempted${NC}"
    if cp .env.template .env.local; then
      env_result="${GREEN}Success${NC}"
    else
      env_result="${RED}Failed${NC}"
    fi
    cd ..
  fi

  results+=("${repo}|${clone_result}|${env_result}|${npm_result}")
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
    # if npm install; then
    #   npm_result="${GREEN}Success${NC}"
    # else
    #   npm_result="${RED}Failed${NC}"
    # fi
    npm_result="${RED}npm install Not attempted${NC}"
    if cp env/.env.template env/.env.local; then
      env_result="${GREEN}Success${NC}"
    else
      env_result="${RED}Failed${NC}"
    fi
    cd ..
  fi

  results+=("${repo}|${clone_result}|${env_result}|${npm_result}")
done

# Step 4: Run docker compose in the current script location
cd ..
docker-compose up -d

# Step 5: Print results
print_results "${results[@]}"