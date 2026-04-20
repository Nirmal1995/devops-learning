#!/usr/bin/env bash
set -e
REGISTRY="europe-west1-docker.pkg.dev/${PROJECT_ID}/devops-learning"

cat > 40-migration-job.yaml <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
  namespace: app
spec:
  backoffLimit: 3
  ttlSecondsAfterFinished: 300
  template:
    metadata:
      labels:
        app: db-migration
    spec:
      restartPolicy: Never
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: migrate
        image: ${REGISTRY}/backend:0.1.0
        command: ["sh", "-c"]
        args:
          - |
            export DATABASE_URL="postgresql://\${DB_USER}:\${DB_PASSWORD}@\${DB_HOST}:\${DB_PORT}/\${DB_NAME}"
            cd /app
            alembic upgrade head
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: backend-config
              key: DB_HOST
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: backend-config
              key: DB_PORT
        - name: DB_NAME
          valueFrom:
            configMapKeyRef:
              name: backend-config
              key: DB_NAME
        - name: DB_USER
          valueFrom:
            configMapKeyRef:
              name: backend-config
              key: DB_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: backend-secrets
              key: DB_PASSWORD
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
YAML

echo "Generated 40-migration-job.yaml"