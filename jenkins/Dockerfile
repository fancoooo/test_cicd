# =====================================================================
#  Image Jenkins tuy bien cho du an: cai san Docker CLI + Trivy.
#  - Docker CLI: de stage "Docker Build & Push" goi `docker build/push`
#    (su dung docker.sock cua host da mount trong docker-compose).
#  - Trivy: de stage "Trivy FS Scan" / "Trivy image scan" chay duoc.
#  Build qua docker-compose.tools.yml (key "build").
# =====================================================================
FROM jenkins/jenkins:lts-jdk17

USER root

# --- Docker CLI (client) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg lsb-release && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg \
        | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list && \
    apt-get update && apt-get install -y --no-install-recommends docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# --- Trivy ---
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
        | sh -s -- -b /usr/local/bin

USER jenkins
