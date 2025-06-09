import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
import subprocess

# Nombre de requêtes à exécuter
NUM_REQUESTS = 1000

# Fonction pour récupérer dynamiquement le nom d’hôte avec Ansible
def get_hostname():
    try:
        result = subprocess.check_output(
            "ANSIBLE_PYTHON_INTERPRETER=auto_silent ansible -i hosts haproxy -m command -a 'hostname' | tail -n 1",
            shell=True, text=True
        ).strip()
        return result
    except subprocess.CalledProcessError as e:
        print(f"Erreur lors de la récupération du hostname : {e}")
        return None

# Fonction pour effectuer une requête HTTP et retourner la première ligne
def fetch_first_line(url):
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        return response.text.strip().splitlines()[0] if response.text else "[Page vide]"
    except Exception as e:
        return f"Erreur: {e}"

def main():
    hostname = get_hostname()
    if not hostname:
        print("Impossible de récupérer le nom d’hôte. Abandon.")
        return

    url = f"http://{hostname}.peperelab.com/proxy/80/"
    print(f"URL utilisée : {url}")
    print(f"Lancement de {NUM_REQUESTS} requêtes en parallèle...")

    results = []

    with ThreadPoolExecutor(max_workers=100) as executor:
        futures = [executor.submit(fetch_first_line, url) for _ in range(NUM_REQUESTS)]

        for i, future in enumerate(as_completed(futures), 1):
            result = future.result()
            print(f"[{i}] {result}")
            results.append(result)

if __name__ == "__main__":
    main()
