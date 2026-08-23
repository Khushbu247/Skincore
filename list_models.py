import os
import json
import urllib.request
import urllib.error

env = {}
if os.path.exists("backend/.env"):
    with open("backend/.env") as f:
        for line in f:
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                env[k.strip()] = v.strip().strip("'").strip('"')

key = env.get("GROQ_API_KEY")
print("Key:", key)

req = urllib.request.Request(
    "https://api.groq.com/openai/v1/models",
    headers={"Authorization": f"Bearer {key}"}
)

try:
    with urllib.request.urlopen(req, timeout=8) as resp:
        data = json.loads(resp.read().decode("utf-8"))
        models = [m["id"] for m in data.get("data", [])]
        print("ACTIVE GROQ MODELS:", models)
except urllib.error.HTTPError as e:
    print("HTTP ERROR:", e.code, e.reason)
    print(e.read().decode("utf-8"))
except Exception as e:
    print("ERROR:", e)
