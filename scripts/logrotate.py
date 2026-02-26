import os
import gzip
import shutil
from datetime import datetime

#Configurations: change these as needed
LOG_DIR = "/var/log/myapp" 
ARCHIVE_DIR = "/var/log/myapp/archive"
MAX_SIZE = 5 * 1024 * 1024 #5MB in bytes
SCRIPT_LOG = "/var/log/logrotate_script.log"

#Create folder archive if it doesn't exist
os.makedirs(ARCHIVE_DIR, exist_ok=True)

#Function to writing logs with timestamp
def log(message):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    entry = f"[{timestamp}] {message}"
    print(entry)
    with open(SCRIPT_LOG, 'a') as f:
        f.write(entry + '\n')

log(f"Starting check file log in {LOG_DIR}")

#Loop through file in LOG_DIR
for filename in os.listdir(LOG_DIR):

    #Skip if its not file .log
    if not filename.endswith('.log'):
        continue
    
    filepath = os.path.join(LOG_DIR, filename)

    #Check file size in bytes
    size = os.path.getsize(filepath)

    #check if file size above 5MB
    if size > MAX_SIZE:
        
        #create archive name with timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        archive_name = f"{filename.replace('.log', '')}_{timestamp}.log.gz"
        archive_path = os.path.join(ARCHIVE_DIR, archive_name)

        log(f"Archiving {filename} (size: {size} bytes)")

        # compress and store to archive folder
        with open(filepath, 'rb') as f_in:
            with gzip.open(archive_path, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)

        log(f"Emptying {filename}")

        # Empty file without deleting it
        open(filepath, 'w').close()

        log(f"Finished: archived as {archive_name}")

    else:
        log(f"Skip { filename} (size: {size} bytes,under threshold)")

log("Check finished")