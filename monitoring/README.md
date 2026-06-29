# Monitoring (Prometheus thuần + Grafana sẵn có)

Cluster đã có sẵn **Grafana** trong namespace `monitoring` nhưng **chưa có Prometheus**
và **không có Prometheus Operator** (không có CRD `ServiceMonitor`). Vì vậy ta dùng
**Prometheus thuần** (deploy bằng manifest), scrape pod qua annotation — không cần Helm.

## Cách hoạt động

1. App expose metrics tại `/actuator/prometheus` (Micrometer + Actuator).
2. Pod app có annotation (trong `k8s/deployment.yaml`):
   `prometheus.io/scrape: "true"`, `prometheus.io/port: "8088"`, `prometheus.io/path: "/actuator/prometheus"`.
3. `monitoring/prometheus.yaml` deploy Prometheus với job `kubernetes-pods` tự phát hiện
   mọi pod có annotation đó và scrape đúng port/path.
4. Grafana (sẵn có) thêm Prometheus làm datasource → vẽ dashboard.

## Cài đặt

```bash
# 1. Deploy Prometheus vao namespace monitoring
kubectl apply -f monitoring/prometheus.yaml
kubectl get pods -n monitoring          # cho prometheus-... Running

# 2. Kiem tra Prometheus thay target app chua
kubectl -n monitoring port-forward svc/prometheus 19090:9090
#   -> http://localhost:19090/targets  : phai thay pod cicd-demo o trang thai UP
```

## Nối Grafana với Prometheus

Mở Grafana sẵn có → **Connections → Data sources → Add data source → Prometheus**:

- URL: `http://prometheus.monitoring.svc.cluster.local:9090`
  (Grafana cùng namespace `monitoring` nên `http://prometheus:9090` cũng được).
- Save & test.

Sau đó **Dashboards → Import** dùng ID:
- **4701** — JVM (Micrometer)
- **11378** — Spring Boot 2.1+ Statistics

> Lưu ý: `monitoring/prometheus.yaml` apply THỦ CÔNG (hạ tầng dùng chung), KHÔNG nằm
> trong thư mục `k8s/` mà ArgoCD quản lý (ArgoCD chỉ deploy app vào namespace `cicd-demo`).
