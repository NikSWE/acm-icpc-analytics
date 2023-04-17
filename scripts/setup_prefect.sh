apt update 
apt install python3-venv python3-pip sqlite3 -y

python3 -m venv venv
source venv/bin/activate

pip install prefect

# Find the public ip of the VM
public_ip=$(curl -s ifconfig.me)

# Prefect Config
prefect config set PREFECT_API_URL=$(echo http://$public_ip:4200/api)
prefect config set PREFECT_SERVER_API_HOST=0.0.0.0
prefect config set PREFECT_SERVER_API_PORT=4200

# Start prefect
tmux new -d -s prefect-server
tmux send-keys -t prefect-server 'prefect server start' ENTER
tmux new -d -s prefect-agent
tmux send-keys -t prefect-agent 'prefect agent start -q default' ENTER
