import requests
from concurrent.futures import ThreadPoolExecutor, as_completed
import subprocess
from collections import Counter
import argparse
import time
import yaml  # PyYAML

def load_config(filename="07config.yaml"):
    try:
        with open(filename, "r") as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Erreur chargement config YAML: {e}")
        return {}

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
    # Charger config YAML
    config = load_config()

    # Extraire valeurs par défaut ou fallback
    default_count = config.get("count", 1000)
    default_threads = config.get("threads", 100)

    # Gestion arguments CLI avec defaults depuis YAML
    parser = argparse.ArgumentParser(description="Effectue des appels HTTP en parallèle et calcule les statistiques.")
    parser.add_argument("count", nargs="?", type=int, default=default_count, help=f"Nombre total d'appels HTTP (défaut: {default_count})")
    parser.add_argument("--threads", type=int, default=default_threads, help=f"Nombre de threads parallèles (défaut: {default_threads})")
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
    response_times = []

    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = [executor.submit(fetch_first_line_with_time, url) for _ in range(num_requests)]

        for i, future in enumerate(as_completed(futures), 1):
            result, duration = future.result()
            if duration is not None:
                response_times.append(duration)
                ms = f"{duration * 1000:.2f} ms"
            else:
                ms = "timeout/erreur"
            print(f"[{i}] {result} | Temps de réponse : {ms}")
            results.append(result)

    # Analyse des réponses
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

    # Temps de réponse
    if response_times:
        avg_time = sum(response_times) / len(response_times) * 1000  # en ms
        min_time = min(response_times) * 1000
        max_time = max(response_times) * 1000
        print("\n--- Temps de réponse ---")
        print(f"Moyen : {avg_time:.2f} ms")
        print(f"Min    : {min_time:.2f} ms")
        print(f"Max    : {max_time:.2f} ms")
    else:
        print("\nAucune réponse réussie pour calculer les temps.")

if __name__ == "__main__":
    main()
