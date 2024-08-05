#!/usr/bin/python3
import xml.etree.ElementTree as ET
import os
import urllib.request
from urllib.error import URLError, HTTPError
import json
import subprocess
import sys

def get_mac_serial_number():
    try:
        output = subprocess.check_output(
            ['ioreg', '-l']
        )
        output = output.decode('utf-8', errors='ignore')  # or use errors='replace'
        
        for line in output.split('\n'):
            if 'IOPlatformSerialNumber' in line:
                serial_number = line.split('=')[-1].strip().replace('"', '')
                return serial_number
    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to get serial number - {e}")
        return None

filename = '/Library/LaunchAgents/ch.pxlm.Nudge.plist'
launch_agent = 'com.pixelmachinery.Nudge'

# Define default URL for the Nudge config file
nudge_config_url_default = 'https://pixel-public-nudge.s3.amazonaws.com/nudge.json'


def download_file_from_url(url, file_location):
    try:
        with urllib.request.urlopen(url) as response:
            content = response.read()

        # Write the content to the specified file location
        with open(file_location, 'wb') as file:
            file.write(content)
            print(f'File downloaded successfully to {file_location}')

    except URLError as e:
        print('URL error:', e.reason)


def get_org_by_serial(api_key, serial):
    url = 'https://i3t3mbmsq1.execute-api.us-east-1.amazonaws.com/default/getOrgBySerial'
    headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'x-api-key': api_key,
    }
    payload = {
        'serial': serial,
    }

    req = urllib.request.Request(url, headers=headers,
                                 data=json.dumps(payload).encode('utf-8'), method='POST')

    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data

    except (URLError, HTTPError) as e:
        # A serious problem happened, like an SSLError or InvalidURL
        print("Error: ", e)
        return None



org = ""
serial_number = get_mac_serial_number()
api_key = sys.argv[1]
if serial_number is not None:
    print(f"Serial number: {serial_number}")
    org_response = get_org_by_serial(api_key, serial_number)
else:
    print("Could not retrieve serial number.")
# Check for the API's success or error status
if org_response is None or org_response["statusCode"] != 200:
    print('Status:', org_response["statusCode"], 'Problem with finding a unique serial' 
          if org_response is not None else 'API call failed')
else:
    org = org_response["body"] + "-"


print(org)

if not os.path.isfile(filename):
    print(f"File {filename} does not exist.")
    exit(1)

nudge_config_url = f'https://pixel-public-nudge.s3.amazonaws.com/{org}nudge.json'

# Download logo
logo_url = f'https://pixel-public-nudge.s3.amazonaws.com/logos/{org}logo.png'
logo_file_location = '/var/tmp/nudge-logo.png'
download_file_from_url(logo_url, logo_file_location)

print(f"Checking if org-specific url exists: {nudge_config_url}")

# Check if the new URL is valid
try:
    with urllib.request.urlopen(nudge_config_url):
        pass
except (URLError, HTTPError) as e:
    print("URL call not 200 and exception, reverting to default")
    nudge_config_url = nudge_config_url_default

print(nudge_config_url)

# Load XML file
tree = ET.parse(filename)
root = tree.getroot()

# Variable to hold state
found_json_url = False

# Locate 'ProgramArguments' key and replace url
for item in root.iter():
    if item.text == 'ProgramArguments':
        found_json_url = False
    elif found_json_url:
        item.text = nudge_config_url
        found_json_url = False
    elif item.text == '-json-url':
        found_json_url = True

# Write back to the file
tree.write(filename)

subprocess.run(['launchctl', 'asuser', '501', 'launchctl', 'unload', filename], check=True)
subprocess.run(['launchctl', 'asuser', '501', 'launchctl', 'load', filename], check=True)
