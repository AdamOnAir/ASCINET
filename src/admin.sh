#!/bin/bash

# Gum Environment Variables
export GUM_INPUT_CURSOR_FOREGROUND="       #0437F2"
export GUM_INPUT_PROMPT="> "
export GUM_INPUT_WIDTH=80

# Server address and port
SERVER_USER="$(gum input --placeholder="Enter Remote User")"
SERVER_IP="gum input --placeholder="Enter Remote IP")"
SERVER_PORT=8080

# List of authorized supervisor computers
SUPERVISORS=("fbdev")
SUPERVISOR_PASSWORD="3310"

# Connect to the Soft-Serve server
exec 3<>/dev/tcp/$SERVER_IP/$SERVER_PORT || exit 1
gum log --level info "Connected to $SERVER_USER@$SERVER_IP:$SERVER_PORT" >&2

# Authenticate supervisor
username=$(gum input --placeholder="Enter Supervisor Username")
is_supervisor=false
for supervisor in "${SUPERVISORS[@]}"; do
    if [ "$supervisor" == "$username" ]; then
        is_supervisor=true
        break
    fi
done

if $is_supervisor; then
    password=$(gum input --password --placeholder="Enter Supervisor Password")
    if [ "$password" == "$SUPERVISOR_PASSWORD" ]; then
        echo "Supervisor $username authenticated."
    else
        gum confirm "Incorrect password for $username" --affirmative "Try Again" || exit 1
    fi
fi

# Send File
send_file() {
    file_path=$(gum file "$(pwd)")
    if [ -n "$file_path" ]; then
        gum log --level info "Sending file: $file_path"
        echo "$file_path" >&3
        scp "$file_path" "$SERVER_USER@$SERVER_IP:~/ASCINET/files/"
    else
        gum log --level error "No file selected"
    fi
}

# View Files
view_files() {
    gum log --level info "Listing files on $SERVER_USER@$SERVER_IP:~/ASCINET/files/"
    echo "/view_files" >&3
    while read -r line; do
        echo "$line"
    done <&3
}

while true; do
    action=$(gum choose "Alert" "Send Message" "Send File" "View Files" "Docs" "Quit")
    case "$action" in
        "Alert")
            ALERT_MSG=$(gum input --placeholder="Alert Message: ")
            gum log --level warn "$ALERT_MSG"
            echo "$ALERT_MSG" >&3
            ;;
        "Send Message")
            message=$(gum input --prompt "Enter the message: ")
            echo "$message" >&3
            gum log --level info "$message"
            ;;
        "Send File")
            send_file
            ;;
        "View Files")
            view_files
            ;;
        "Docs")
            cd ..
	    soft
	    cd src
            ;;
        "Quit")
            exit 0
            ;;
    esac
done
