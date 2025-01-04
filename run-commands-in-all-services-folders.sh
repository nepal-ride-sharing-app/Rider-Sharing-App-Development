#!/bin/bash

# Prompt the user to input multiple commands separated by &&
echo "Enter the commands to execute (separated by &&):"
read -r user_commands

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m" # No color

# Arrays to store successful and failed directories
success_dirs=()
failed_dirs=()

FOLDER_TO_SEARCH="services"
# Navigate to the services directory
cd "${FOLDER_TO_SEARCH}" || exit

# Loop through all directories in the current directory
for dir in */; do
  if [ -d "$dir" ]; then
    echo "Entering directory: $dir"
    cd "$dir" || exit  # Navigate into the directory
    
    echo "Running commands: $user_commands"
    if eval "$user_commands"; then
      echo -e "${GREEN}Success: ${FOLDER_TO_SEARCH}/$dir${NC}"
      success_dirs+=("${FOLDER_TO_SEARCH}/$dir")
    else
      echo -e "${RED}Failed: ${FOLDER_TO_SEARCH}/$dir${NC}"
      failed_dirs+=("${FOLDER_TO_SEARCH}/$dir")
    fi

    cd .. || exit  # Navigate back to the parent directory
  fi
done

# Final summary
echo -e "\nCommands executed: $user_commands"

echo -e "\n${GREEN}*** Directories where commands succeeded: ***${NC} \n"
for dir in "${success_dirs[@]}"; do
  echo -e "${GREEN}$dir${NC}"
done

echo -e "\n${RED}--- Directories where commands failed: ---${NC} \n"
for dir in "${failed_dirs[@]}"; do
  echo -e "${RED}$dir${NC}"
done
