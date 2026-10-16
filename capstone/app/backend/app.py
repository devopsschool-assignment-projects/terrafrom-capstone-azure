"""Capstone backend: a tiny guest-book API.

  GET  /api/health     -> is the app (and its database) alive?
  GET  /api/info       -> student id, pod name, database status, banner from Key Vault
  GET  /api/messages   -> latest 20 messages
  POST /api/messages   -> {"author": "...", "text": "..."}

The banner is read from Azure Key Vault using the pod's Entra ID workload
identity - there is no password for Key Vault anywhere in this app.
"""
import logging
import os
import socket
import threading
import time

import psycopg2
from flask import Flask, jsonify, request

app = Flask(__name__)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("backend")

STUDENT_ID = os.getenv("STUDENT_ID", "unknown")
KEYVAULT_URL = os.getenv("KEYVAULT_URL", "")
BANNER_SECRET_NAME = os.getenv("BANNER_SECRET_NAME", "app-banner")
FALLBACK_BANNER = "(banner not loaded - Key Vault not reachable)"

_banner_cache = {"value": None, "source": "none", "error": None, "at": 0.0}
_db_ready = threading.Event()


def connect():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "postgres"),
        dbname=os.getenv("DB_NAME", "capstone"),
        user=os.getenv("DB_USER", "capstone"),
        password=os.getenv("DB_PASSWORD", ""),
        connect_timeout=3,
    )


def init_db():
    """Create the table. The database pod may start after us, so retry."""
    while not _db_ready.is_set():
        try:
            with connect() as conn, conn.cursor() as cur:
                cur.execute(
                    """CREATE TABLE IF NOT EXISTS messages (
                           id SERIAL PRIMARY KEY,
                           author TEXT NOT NULL,
                           body TEXT NOT NULL,
                           created_at TIMESTAMPTZ DEFAULT now())"""
                )
            _db_ready.set()
            log.info("database ready")
        except Exception as exc:  # noqa: BLE001
            log.warning("database not ready yet: %s", exc)
            time.sleep(3)


def get_banner():
    """Read the banner secret from Key Vault (cached for 60 seconds)."""
    now = time.time()
    if _banner_cache["value"] and now - _banner_cache["at"] < 60:
        return _banner_cache
    if not KEYVAULT_URL:
        _banner_cache.update(value=FALLBACK_BANNER, source="fallback", error="KEYVAULT_URL not set", at=now)
        return _banner_cache
    try:
        from azure.identity import DefaultAzureCredential
        from azure.keyvault.secrets import SecretClient

        client = SecretClient(vault_url=KEYVAULT_URL, credential=DefaultAzureCredential())
        value = client.get_secret(BANNER_SECRET_NAME).value
        _banner_cache.update(value=value, source="key-vault", error=None, at=now)
    except Exception as exc:  # noqa: BLE001
        log.warning("could not read Key Vault: %s", exc)
        _banner_cache.update(value=FALLBACK_BANNER, source="fallback", error=str(exc)[:200], at=now - 50)
    return _banner_cache


@app.get("/api/health")
def health():
    try:
        with connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT 1")
        return jsonify(status="ok", database="up"), 200
    except Exception as exc:  # noqa: BLE001
        return jsonify(status="degraded", database="down", error=str(exc)[:200]), 503


@app.get("/api/info")
def info():
    banner = get_banner()
    db_status = "up"
    try:
        with connect() as conn, conn.cursor() as cur:
            cur.execute("SELECT version()")
            db_version = cur.fetchone()[0].split(",")[0]
    except Exception:  # noqa: BLE001
        db_status, db_version = "down", None
    return jsonify(
        student=STUDENT_ID,
        pod=socket.gethostname(),
        database=db_status,
        database_version=db_version,
        banner=banner["value"],
        banner_source=banner["source"],
        banner_error=banner["error"],
    )


@app.get("/api/messages")
def list_messages():
    with connect() as conn, conn.cursor() as cur:
        cur.execute("SELECT id, author, body, created_at FROM messages ORDER BY id DESC LIMIT 20")
        rows = [
            {"id": r[0], "author": r[1], "text": r[2], "created_at": r[3].isoformat()}
            for r in cur.fetchall()
        ]
    return jsonify(rows)


@app.post("/api/messages")
def add_message():
    data = request.get_json(silent=True) or {}
    author = str(data.get("author", "")).strip()[:50]
    text = str(data.get("text", "")).strip()[:300]
    if not author or not text:
        return jsonify(error="author and text are required"), 400
    with connect() as conn, conn.cursor() as cur:
        cur.execute(
            "INSERT INTO messages (author, body) VALUES (%s, %s) RETURNING id", (author, text)
        )
        new_id = cur.fetchone()[0]
    return jsonify(id=new_id, author=author, text=text), 201


threading.Thread(target=init_db, daemon=True).start()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
