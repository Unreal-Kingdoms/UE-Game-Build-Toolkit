#!/bin/bash

echo "UE5 Game Build Pipeline"
echo "Written by Trident_For_U (Tristan Poland) 2023"


# Function to install dialog
install_dialog() {
    echo "Checking system..."
    if [[ -n "$(command -v apt-get)" ]]; then
        sudo apt-get update
        sudo apt-get install -y dialog
    elif [[ -n "$(command -v yum)" ]]; then
        sudo yum install -y dialog
    else
        echo "Unsupported package manager. Please install dialog manually."
        exit 1
    fi
}

# Check if dialog is installed
if [[ -z "$(command -v dialog)" ]]; then
    echo "Dialog is not installed."
    
    # Ask user if they want to install dialog
    read -p "Do you want to install dialog? (y/n): " choice
    case $choice in
        [Yy]*)
            install_dialog
            ;;
        *)
            echo "Exiting script without installing dialog."
            exit 1
            ;;
    esac
fi

# Function to perform action for Option 1
function option1_action() {
    clear
    echo "Running pipeline setup..."
    
    #Install MiniKube
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube

    #Crictl Setup
    VERSION="v1.28.0"
    #Download
    wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
    #Install
    sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
    #clean-up
    rm -f crictl-$VERSION-linux-amd64.tar.gz

    #Conntrack installation
    sudo apt-get install -y conntrack

    # Check if docker is installed
    if [[ -z "$(command -v docker)" ]]; then
        echo "Docker is not installed, installing now..."
        sudo apt-get install -y docker.io
    fi

    # Check if KubeCTL is installed
    if [[ -z "$(command -v kubectl)" ]]; then
        echo "KubeCTL is not installed, installing it now..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    fi
}

# Function to perform action for Option 2
function option2_action() {
    clear
    echo "Re-adding pipeline task..."

    #Add pipeline
    kubectl apply --filename ./ue5-game-pipeline.yaml

    #Define Tasks
    kubectl apply --filename ./ue5-build-task.yaml

    #Add pipelineRun
    kubectl apply --filename ./ue5-game-pipeline-run.yaml

}

# Function to perform action for Option 3
function option3_action() {
    clear
    echo "Starting pipeline task..."
    bash ./start.sh
}

# Function to perform action for Option 4
function option4_action() {
    clear
    echo "Fixing MiniKube drivers..."

    minikube config set driver docker
    minikube delete

}

# Function to display copyright dialoghttps://github.com/Unreal-Kingdoms/UE-Game-Build-Toolkit/blob/main/setup.sh
about_dialog() {
    dialog --backtitle "About" \
           --title "Copyright" \
           --msgbox "UE Game Build toolkit (C) Tristan Poland 2023" 10 40
}

# Display a two-option dialog
dialog --backtitle "(C) Tristan J. Poland 2023" \
       --title "Pipeline Actions" \
       --menu "Select a pipeline option:" 12 40 2 \
       1 "Run pipeline setup" \
       2 "Add pipeline task" \
       3 "Start UE pipeline system" \
       4 "Fix-Up MiniKube Drivers" \
       5 "About" \
       2>/tmp/choice

# Get the user's choice
choice=$(cat /tmp/choice)

# Execute the corresponding function based on the choice
case $choice in
    1) option1_action ;;
    2) option2_action ;;
    3) option3_action ;;
    4) option4_action ;;
    5) about_dialog ;;
    *) clear & echo "Operation Canceled";;
esac

# Clean up temporary file
rm -f /tmp/choice
