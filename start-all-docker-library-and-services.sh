# Import environment variables from env.sh
source "$(dirname "$0")/env.sh"

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
    do script "cd \"$(pwd)/${service_dir}\" && npm run serve"
    activate
end tell
EOF
    else
      echo "Skipping ${service}: Directory or package.json not found."
    fi
  done
}

serve_libraries_in_new_terminal() {
  echo "Launching 'npm run dev' in new Terminal windows for library repositories..."
  cd libraries || { echo "libraries folder not found"; return 1; }
  for library in "${LIBRARIES_REPOS[@]}"; do
    if [ -d "${library}" ] && [ -f "${library}/package.json" ]; then
      echo "Launching library: ${library}..."
      osascript <<EOF
tell application "Terminal"
    do script "cd \"$(pwd)/${library}\" && npm run dev"
    activate
end tell
EOF
    else
      echo "Skipping ${library}: Directory or package.json not found."
    fi
  done
  cd ..
}

echo "Starting Docker services..."
docker-compose up -d --build
# serve libraries in new Terminal windows
serve_libraries_in_new_terminal

# Launch services in new Terminal windows
serve_services_in_new_terminal