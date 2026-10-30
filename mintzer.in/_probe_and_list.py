import socket
from pathlib import Path

hosts = ["mintzer.in", "ftp.mintzer.in", "ssh.hostinger.com"]
ports = [21, 22, 2222, 443, 65002]
for h in hosts:
    for p in ports:
        s = socket.socket()
        s.settimeout(4)
        try:
            r = s.connect_ex((h, p))
            print(f"{h}:{p}", "OPEN" if r == 0 else f"fail/{r}")
        except Exception as e:
            print(f"{h}:{p}", "ERR", e)
        finally:
            s.close()

live = Path(r"D:\dev\mintzer-app\mintzer.in\mintzer\mintzer\assets\images")
for sub in ["branding", "hero", "footer"]:
    print("---", sub)
    for f in sorted((live / sub).iterdir()):
        if f.is_file():
            print(f.name, f.stat().st_size)
