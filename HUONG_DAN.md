# Hướng dẫn học CI/CD theo sơ đồ CICD.png

Dự án Spring Boot này tái hiện **đúng từng bước** trong sơ đồ bạn cung cấp. Mục tiêu là bạn vừa có code chạy được, vừa hiểu mỗi mảnh ghép DevOps làm gì và nằm ở file nào.

---

## 1. Đọc lại sơ đồ — pipeline gồm 2 nửa

**Nửa trên (Jenkins CI Job):**

> Developer **push code** → GitHub → Jenkins **pull code** → **OWASP** (dependency check) → **SonarQube** (code & quality gate) → **Trivy** (filesystem scan) → **Docker** build & push.

**Nửa dưới (Jenkins CD Job):**

> **Update Docker image version** → push **GitHub** → **ArgoCD** pull code → **deploy lên Kubernetes** → **Prometheus + Grafana** monitoring → **notify qua email (Gmail)**.

Điểm cốt lõi: đây là mô hình **GitOps**. Jenkins CD **không** `kubectl apply` trực tiếp. Nó chỉ sửa số version image trong file YAML rồi đẩy lên Git; ArgoCD theo dõi Git và tự đồng bộ lên cluster.

---

## 2. Mỗi icon trong ảnh ↔ file nào trong dự án

| Bước trong ảnh | Công cụ | File / cấu hình tương ứng |
|---|---|---|
| Push / Pull code | GitHub + Git | repo này, `stage('Pull Code')` trong `Jenkinsfile` |
| Dependency check | OWASP | plugin trong `pom.xml`, `stage('OWASP Dependency Check')` |
| Code & quality gate | SonarQube | `sonar-project.properties`, `stage('SonarQube Analysis')` + `Quality Gate` |
| Filesystem scan | Trivy | `stage('Trivy FS Scan')` trong `Jenkinsfile` |
| Docker build & push | Docker | `Dockerfile`, `stage('Docker Build & Push')` |
| Update image version | Jenkins CD | `Jenkinsfile-CD` (`sed` sửa `k8s/deployment.yaml`) |
| Pull code & deploy K8s | ArgoCD | `argocd/application.yaml` |
| Chạy ứng dụng | Kubernetes | `k8s/deployment.yaml`, `service.yaml`, `namespace.yaml` |
| Monitoring | Prometheus (thuần) + Grafana | `monitoring/prometheus.yaml`, annotation trong `k8s/deployment.yaml`, Actuator trong `application.yml` |
| Notify on email | Gmail/SMTP | khối `post { }` trong `Jenkinsfile` (`emailext`) |

---

## 3. Lộ trình học theo 4 cấp độ

Đừng dựng tất cả cùng lúc. Làm theo thứ tự, mỗi cấp độ chạy được rồi mới lên cấp tiếp theo.

### Cấp 1 — Chạy app trên máy (15 phút)

Cần: JDK 17, Maven.

```bash
cd springboot-cicd-demo
mvn clean verify          # build + chạy test + coverage JaCoCo
mvn spring-boot:run       # chạy app
```

Mở thử:
- http://localhost:8088/ → trả JSON `message/version`
- http://localhost:8088/api/greet
- http://localhost:8088/actuator/health → `{"status":"UP"}`
- http://localhost:8088/actuator/prometheus → metrics dạng text (Prometheus đọc cái này)

Báo cáo coverage: `target/site/jacoco/index.html`.

### Cấp 2 — Đóng gói Docker (15 phút)

Cần: Docker.

```bash
docker build -t cicd-demo:local .
docker run -p 8088:8088 cicd-demo:local
```

`Dockerfile` dùng **multi-stage**: stage build dùng Maven, stage runtime chỉ chứa JRE alpine + chạy bằng user non-root → image nhỏ, an toàn hơn (chính là image mà Trivy sẽ quét).

### Cấp 3 — Dựng pipeline CI (Jenkins + SonarQube)

Dựng nhanh stack công cụ bằng Docker Compose:

```bash
docker compose -f docker-compose.tools.yml up -d
```

Mở:
- Jenkins: http://localhost:8081 (lấy mật khẩu: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`)
- SonarQube: http://localhost:9000 (admin/admin)

> Compose này **không** còn Prometheus/Grafana, vì app deploy lên K8s thì monitoring phải chạy trong cluster (xem Cấp 4).

Trong Jenkins, cài plugin: *Pipeline, Git, Docker Pipeline, SonarQube Scanner, OWASP Dependency-Check, Email Extension, Eclipse Temurin installer*.

Cấu hình **Manage Jenkins → Tools**: thêm JDK tên `jdk17` và Maven tên `maven3` (đúng tên đã dùng trong `Jenkinsfile`).

Cấu hình **Manage Jenkins → System**:
- SonarQube servers: tên `sonarqube`, URL `http://sonarqube:9000`, token tạo từ SonarQube (My Account → Security).
- Email/SMTP cho `emailext` (xem mục 4).

Thêm **Credentials**:
- `dockerhub-cred` — tài khoản Docker Hub.
- `github-cred` — Personal Access Token GitHub (để CD push).
- token SonarQube.

Cài **Trivy** trên agent Jenkins (hoặc thêm 1 stage cài trong pipeline).

Tạo **Pipeline job** trỏ vào `Jenkinsfile` của repo. Mỗi lần build sẽ chạy lần lượt 8 stage đúng như nửa trên của ảnh. Nhớ sửa các biến trong `environment {}` (`IMAGE_NAME`, URL repo Git) cho đúng của bạn.

#### Làm sao "push code thì Jenkins tự pull về"?

GitHub **không** đẩy code thẳng vào Jenkins. Push chỉ đưa code lên GitHub. Jenkins biết được nhờ một trong hai cơ chế dưới đây, rồi mới chủ động `git pull`:

**Cách 1 — Webhook (khuyến nghị, gần như tức thì).** Khi bạn `git push`, GitHub gửi một HTTP POST tới Jenkins báo "có commit mới" → Jenkins tự kích hoạt build. Thứ tự thật là: *push → GitHub gọi Jenkins → Jenkins pull về*.

Các bước cấu hình:

1. Trong `Jenkinsfile` đã có sẵn `triggers { githubPush() }`.
2. Job Jenkins → **Configure → Build Triggers** → tick **"GitHub hook trigger for GITScm polling"**.
3. Trên GitHub: **repo → Settings → Webhooks → Add webhook**:
   - *Payload URL*: `http://<JENKINS_URL>/github-webhook/` (nhớ có dấu `/` cuối).
   - *Content type*: `application/json`.
   - *Which events*: chọn **Just the push event**.
4. Test: push 1 commit → vào tab **Recent Deliveries** của webhook xem GitHub gọi có trả `200` không; đồng thời job Jenkins phải tự chạy.

Lưu ý quan trọng: GitHub (trên internet) phải **gọi tới được** URL Jenkins. Nếu Jenkins chạy local (`localhost:8081`), GitHub không với tới được → dùng **ngrok** hoặc **cloudflare tunnel** để tạo URL public:

```bash
ngrok http 8081          # lấy URL https://xxxx.ngrok.io rồi đặt làm Payload URL + /github-webhook/
```

**Cách 2 — Poll SCM (dự phòng, có độ trễ).** Không cần webhook, không cần URL public. Jenkins tự hỏi GitHub theo lịch. Trong `Jenkinsfile`, bỏ comment dòng `pollSCM('H/2 * * * *')` (cứ ~2 phút kiểm tra một lần). Nhược điểm: tốn tài nguyên và push xong phải chờ tới lượt poll mới build.

Tóm tắt khác biệt: webhook là "GitHub gõ cửa báo Jenkins"; polling là "Jenkins liên tục tự đi hỏi". Webhook nhanh và nhẹ hơn, nên ưu tiên dùng khi Jenkins có URL public.

### Cấp 4 — CD GitOps (ArgoCD + Kubernetes + Monitoring)

Cần: 1 cluster K8s (minikube / kind / k3s đều được) + ArgoCD.

1. Cài ArgoCD: `kubectl create namespace argocd && kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
2. Sửa `repoURL` trong `argocd/application.yaml` thành repo của bạn, rồi `kubectl apply -f argocd/application.yaml`.
3. Tạo job Jenkins CD tên `cicd-demo-CD` trỏ vào `Jenkinsfile-CD`. CI job sẽ tự trigger nó.
4. Luồng hoàn chỉnh: CI build image tag mới → CD `sed` đổi tag trong `k8s/deployment.yaml` → push Git → ArgoCD phát hiện thay đổi → deploy lên K8s.

#### Monitoring: Prometheus thuần + Grafana sẵn có

Cluster của bạn đã có **Grafana** trong namespace `monitoring` nhưng **chưa có Prometheus** và không có Prometheus Operator. Nên ta deploy **Prometheus thuần** bằng manifest, scrape pod qua annotation (không cần Helm).

```bash
# 1. Deploy Prometheus vao namespace monitoring
kubectl apply -f monitoring/prometheus.yaml
kubectl get pods -n monitoring          # cho prometheus-... Running

# 2. Kiem tra Prometheus thay target app chua
kubectl -n monitoring port-forward svc/prometheus 19090:9090
#   -> http://localhost:19090/targets : pod cicd-demo phai o trang thai UP
```

Nối Grafana (sẵn có) với Prometheus: **Connections → Data sources → Add → Prometheus**, URL `http://prometheus.monitoring.svc.cluster.local:9090`. Rồi **Dashboards → Import** ID **4701** (JVM Micrometer) và **11378** (Spring Boot).

Cách hoạt động: app expose `/actuator/prometheus` → Prometheus đọc annotation `prometheus.io/scrape` trên pod (đã đặt trong `k8s/deployment.yaml`) để tự tìm và scrape → Grafana vẽ dashboard. Chi tiết ở `monitoring/README.md`.

> `monitoring/prometheus.yaml` apply **thủ công** (hạ tầng dùng chung), không nằm trong `k8s/` mà ArgoCD quản lý.

---

## 4. Notify qua email (icon Gmail)

Trong `Jenkinsfile`, khối `post { success/failure }` dùng `emailext` gửi mail. Để gửi qua Gmail:

- Bật 2FA cho tài khoản Google, tạo **App Password**.
- Manage Jenkins → System → Extended E-mail Notification: SMTP `smtp.gmail.com`, port `465`, SSL, dùng App Password.
- Địa chỉ nhận đã đặt sẵn là `vietxuyen97@gmail.com` — đổi nếu cần.

---

## 5. Quality Gate — vì sao build có thể "fail" (và đó là điều tốt)

Pipeline cố tình chặn code kém chất lượng / có lỗ hổng:

- **OWASP**: `failBuildOnCVSS=7` trong `pom.xml` → có thư viện dính CVE High/Critical là fail.
- **SonarQube**: stage `Quality Gate` + `waitForQualityGate abortPipeline: true` → không đạt cổng chất lượng (coverage, bug, code smell) là dừng.
- **Trivy**: hiện để `--exit-code 0` (chỉ cảnh báo, không chặn) cho dễ học. Khi muốn siết, đổi thành `--exit-code 1`.

Đây chính là tinh thần "shift-left security": chặn lỗi sớm trong pipeline thay vì để lên production.

---

## 6. Thứ tự nên làm tiếp

1. Đẩy thư mục `springboot-cicd-demo` này lên 1 repo GitHub của bạn.
2. Sửa các placeholder: `your-username`, `your-dockerhub-username`, URL repo.
3. Đi từ Cấp 1 → 4. Mỗi cấp chạy được mới sang cấp sau.

Mọi placeholder cần đổi đều được đánh dấu bằng `your-...` trong các file. Chúc bạn học vui!
