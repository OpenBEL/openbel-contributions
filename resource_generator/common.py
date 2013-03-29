# coding: utf-8

from ftplib import FTP
import gzip
import os
import shutil
import time
import urllib.parse
import urllib.request

def download(url, fileName=None):
    def getFileName(url,openUrl):
        if 'Content-Disposition' in openUrl.info():
            # If the response has Content-Disposition, try to get filename from it
            cd = dict(map(
                lambda x: x.strip().split('=') if '=' in x else (x.strip(),''),
                openUrl.info()['Content-Disposition'].split(';')))
            if 'filename' in cd:
                filename = cd['filename'].strip("\"'")
                if filename: return filename
        # if no filename was found above, parse it out of the final URL.
        return os.path.basename(urllib.parse.urlsplit(openUrl.url)[2])

    if url.startswith("ftp://"):
        urltokens = urllib.parse.urlsplit(url)
        ftp = FTP(urltokens.netloc)
        ftp.login()
        moddt = ftp.sendcmd("MDTM " + urltokens.path)
        if fileName is None:
            fileName = os.path.basename(urltokens.path)
        with open(fileName, "wb") as ftpf, open(fileName + ".info", 'w') as info:
            ftp.retrbinary("RETR " + urltokens.path, ftpf.write)
            info.write("URL: " + url + "\n")
            info.write("Filename: " + fileName + "\n")
            info.write("Last modified: " + moddt.split(" ")[1] + "\n")
            info.write("Downloaded at: " + time.strftime("%Y-%m-%d %H:%M:%S") + "\n")
    else:
        with urllib.request.urlopen(url) as r, open(fileName, 'wb') as f, open(fileName + ".info", 'w') as info:
            fileName = fileName or getFileName(url,r)
            shutil.copyfileobj(r,f)
            info.write("URL: " + url + "\n")
            info.write("Filename: " + fileName + "\n")
            if 'Last-Modified' in r.info():
                info.write("Last modified: " + r.info()['Last-Modified'].strip("\"'"))
            info.write("Downloaded at: " + time.strftime("%Y-%m-%d %H:%M:%S") + "\n")

def gzip_to_text(gzip_file, encoding="ascii"):
    with gzip.open(gzip_file) as gzf:
        for line in gzf:
            yield str(line, encoding)
