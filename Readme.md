# Rider App Setup

This document provides instructions for setting up the Rider App development environment using the provided `initialize-rider-app-setup.sh` script.
Make sure that you give enough permission to run the script using `chmod +x initialize-rider-app-setup.sh`

## Prerequisites

Before running the setup script, ensure you have the following prerequisites installed:

- **Node.js** (>= 18.0.0): [Download Node.js](https://nodejs.org/en/download/)
- **npm** (>= 6.0.0): [Download npm](https://nodejs.org/en/download/)
- **git** (>= 2.30.0): [Download git](https://git-scm.com/downloads)
- **Docker** (>= 20.0.0): [Download Docker](https://docs.docker.com/get-docker/)
- **Docker Compose** (>= 1.29.2): [Download Docker Compose](https://docs.docker.com/compose/install/)

## Steps Handled by the Script

The `initialize-rider-app-setup.sh` script performs the following steps:

1. **Check Prerequisites**: Ensures that Node.js, npm, git, Docker, and Docker Compose are installed.
2. **Install Serverless Globally**: Installs the Serverless framework globally using npm.
3. **Install AWS CLI**: Installs the AWS CLI using Homebrew.
4. **Copy .serverless Folder**: Copies the `.serverless` folder to the service directories.
5. **Prepare Docker Environment**: Copies `.env.template` to `.env` for Docker Compose.
6. **Prompt for Environment Variables**: Asks the user to update the `.env` file with their credentials.
7. **Run Docker Compose and Initialize Services**: Provides the command to start the services using Docker Compose as well as open terminal for services

## Environment Variables

Before running Docker Compose, ensure you have updated the environment variables in the `.env` file located in the root directory. Refer to the `.env.template` file for the required variables.

Additionally, update the `.env` files inside the projects of the `services` folder with your credentials.

## Running Docker Compose

After updating the environment variables, run the following command to start the services:

```sh
docker-compose up -d --build
```
