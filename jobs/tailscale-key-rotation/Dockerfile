FROM python:3.12-slim

RUN useradd -m -u 10001 job && pip install --no-cache-dir google-cloud-secret-manager

WORKDIR /app
COPY src/rotate.py /app/rotate.py
RUN chown -R job:job /app
USER job

ENTRYPOINT ["python3", "/app/rotate.py"]
