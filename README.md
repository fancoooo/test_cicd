# Spring Boot CI/CD Demo

Dự án mẫu để học pipeline CI/CD đầy đủ theo sơ đồ GitOps:

**CI (Jenkins):** Pull code → OWASP dependency check → SonarQube quality gate → Trivy scan → Docker build & push.
**CD (Jenkins + ArgoCD):** Update image version → push Git → ArgoCD sync → deploy K8s → Prometheus/Grafana monitoring → email notify.

> Đọc **[HUONG_DAN.md](./HUONG_DAN.md)** để có hướng dẫn học từng bước (tiếng Việt).

## Chạy nhanh

```bash
mvn spring-boot:run          # chạy app local
docker build -t cicd-demo .  # đóng gói
```

App: http://localhost:8080 · Health: `/actuator/health` · Metrics: `/actuator/prometheus`

## Cấu trúc

```
├── src/                       # Spring Boot app (Maven) + tests
├── Dockerfile                 # multi-stage build, non-root
├── Jenkinsfile                # CI job (nửa trên sơ đồ)
├── Jenkinsfile-CD             # CD job GitOps (nửa dưới sơ đồ)
├── sonar-project.properties   # cấu hình SonarQube
├── k8s/                       # manifests Kubernetes + ServiceMonitor
├── argocd/application.yaml    # ArgoCD Application (GitOps)
├── monitoring/prometheus.yml  # cấu hình Prometheus
└── docker-compose.tools.yml   # Jenkins + SonarQube + Prometheus + Grafana local
```
