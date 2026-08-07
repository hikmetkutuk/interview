import json
import os
import resource
import subprocess
import tempfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


MAX_REQUEST_BYTES = 64 * 1024
TIMEOUT_SECONDS = 10


def limited_process():
    limits = [
        (resource.RLIMIT_CPU, (5, 5)),
        (resource.RLIMIT_AS, (256 * 1024 * 1024, 256 * 1024 * 1024)),
        (resource.RLIMIT_FSIZE, (2 * 1024 * 1024, 2 * 1024 * 1024)),
        (resource.RLIMIT_NOFILE, (32, 32)),
        (resource.RLIMIT_NPROC, (32, 32)),
    ]
    for kind, limit in limits:
        try:
            resource.setrlimit(kind, limit)
        except (OSError, ValueError):
            pass


def runner_env(workdir):
    return {
        "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        "HOME": workdir,
        "TMPDIR": workdir,
        "GOCACHE": os.path.join(workdir, "go-build"),
        "GOMODCACHE": os.path.join(workdir, "go-mod"),
        "GOTMPDIR": workdir,
        "HTTP_PROXY": "",
        "HTTPS_PROXY": "",
        "http_proxy": "",
        "https_proxy": "",
        "NO_PROXY": "*",
        "no_proxy": "*",
    }


def command_for(language, code, workdir):
    if language == "python":
        return ["python3", "-I", "-S", "-c", code]
    if language in ("javascript", "typescript"):
        return ["node", "--no-warnings", "-e", code]
    if language == "java":
        source = os.path.join(workdir, "Main.java")
        with open(source, "w", encoding="utf-8") as file:
            file.write(code)
        return ["sh", "-c", f"javac {source} && java -cp {workdir} Main"]
    if language == "go":
        source = os.path.join(workdir, "main.go")
        with open(source, "w", encoding="utf-8") as file:
            file.write(code)
        return ["go", "run", source]
    return ["node", "--no-warnings", "-e", code]


def execute(code, language, stdin):
    with tempfile.TemporaryDirectory(prefix="run-") as workdir:
        os.makedirs(os.path.join(workdir, "go-build"), exist_ok=True)
        os.makedirs(os.path.join(workdir, "go-mod"), exist_ok=True)
        cmd = command_for(language, code, workdir)
        try:
            result = subprocess.run(
                cmd,
                input=stdin,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                cwd=workdir,
                env=runner_env(workdir),
                timeout=TIMEOUT_SECONDS,
                preexec_fn=limited_process,
                check=False,
            )
            return {"output": result.stdout}
        except subprocess.TimeoutExpired as err:
            output = err.stdout or ""
            if isinstance(output, bytes):
                output = output.decode("utf-8", errors="replace")
            return {"output": output, "error": "execution timed out"}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/healthz":
            self.send_json({"error": "not found"}, 404)
            return
        self.send_json({"status": "ok"})

    def do_POST(self):
        if self.path != "/execute":
            self.send_json({"error": "not found"}, 404)
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            self.send_json({"error": "invalid content length"}, 400)
            return

        if length <= 0 or length > MAX_REQUEST_BYTES:
            self.send_json({"error": "request too large"}, 413)
            return

        try:
            payload = json.loads(self.rfile.read(length))
        except json.JSONDecodeError:
            self.send_json({"error": "invalid json"}, 400)
            return

        code = payload.get("code", "")
        language = payload.get("language", "")
        stdin = payload.get("stdin", "")
        if not isinstance(code, str) or not isinstance(language, str) or not isinstance(stdin, str):
            self.send_json({"error": "invalid payload"}, 400)
            return

        self.send_json(execute(code, language, stdin))

    def send_json(self, payload, status=200):
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8090"))
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
