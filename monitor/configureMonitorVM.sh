#!/bin/bash

# disable exit on error
set +e

ExecuteCommand() {

    retryCounter=1
    while [ $retryCounter -le 3 ]
    do
        echo "Try no $retryCounter: Command: $1"
        # Sleep to allow the servers to recover in case the server was unable to serve the request
	    sleep $retryCounter
	    $1
        if [ $? -eq 0 ]; then
	       return
	    fi
	    retryCounter=$((retryCounter+1))
    done
    >&2 echo "Error executing command: $1"
    # Exit if all the retries failed
    exit 1
}

# Update
ExecuteCommand "apt-get -y update"
# Install pip
ExecuteCommand "apt-get install -y python3-pip"
# Upgrade pip
ExecuteCommand "python3 -m pip install -U pip"
# Install pyhdb
ExecuteCommand "pip3 install pyhdb"
