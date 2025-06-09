import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
import subprocess
from collections import Counter
import argparse
import time

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

def fetch_first_line_with_time(url):
    try:
        start_time = time.time()
        response = requests.get(url, timeout=10)
        duration = time.time() - start_time

        response.raise_for_status()
        first_line = response.text.strip().splitlines()[0] if response.text else ""
        return first_line, duration
    except Exception as e:
        return f"Erreur: {e}", None

def main():
    # Gérer les arguments
    parser = argparse.ArgumentParser(description="Effectue des appels HTTP en parallèle et calcule les statistiques.")
    parser.add_argument("count", nargs="?", type=int, default=1000, help="Nombre total d'appels HTTP (par défaut: 1000)")
    parser.add_argument("--threads", type=int, default=100, help="Nombre de threads parallèles (par défaut: 100)")
    args = parser.parse_args()

    num_requests = args.count
    num_threads = args.threads

    hostname = get_hostname()
    if not hostname:
        print("Impossible de récupérer le nom d’hôte. Abandon.")
        return

    url = f"http://{hostname}.peperelab.com/proxy/80/"
    print(f"URL utilisée : {url}")
    print(f"Lancement de {num_requests} requêtes avec {num_threads} threads...\n")

    results = []

    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = [executor.submit(fetch_first_line_with_time, url) for _ in range(num_requests)]

        for i, future in enumerate(as_completed(futures), 1):
            result, duration = future.result()
            ms = f"{duration*1000:.2f} ms" if duration is not None else "timeout/erreur"
            print(f"[{i}] {result} | Temps de réponse : {ms}")
            results.append(result)

    # Analyse des résultats
    counts = Counter()
    for line in results:
        if "Hostname: web1" in line:
            counts["web1"] += 1
        elif "Hostname: web2" in line:
            counts["web2"] += 1
        else:
            counts["autres"] += 1

    total = len(results)
    print("\n--- Statistiques ---")
    for host in ["web1", "web2", "autres"]:
        count = counts[host]
        pourcentage = (count / total) * 100 if total else 0
        print(f"{host} : {count} réponses ({pourcentage:.2f}%)")

if __name__ == "__main__":
    main()
