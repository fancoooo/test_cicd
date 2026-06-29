# ---------- Stage 1: Build ----------
# Build bang Maven trong container de khong phu thuoc may local
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Cache dependency: copy pom truoc, tai dependency, roi moi copy source
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY src ./src
# Bo qua test o day vi test da chay o stage CI cua Jenkins
RUN mvn -B clean package -DskipTests

# ---------- Stage 2: Runtime ----------
# Image nho, chi chua JRE -> giam be mat tan cong (Trivy se quet image nay)
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Tao user khong phai root (best practice bao mat)
RUN addgroup -S app && adduser -S app -G app
USER app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8088

# Healthcheck dung endpoint actuator
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s \
  CMD wget -qO- http://localhost:8088/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
