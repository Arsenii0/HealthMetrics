# HealthMetrics

A comprehensive digital health platform designed to help individuals with diet realted health conditions identify food triggers and manage symptoms through intelligent meal and symptom tracking.

## Purpose

HealthMetrics empowers users to take control of their digestive health by providing:
- **Effortless meal logging** with photo capture and notes
- **Quick symptom tracking** with one-tap intensity rating
- **AI-powered insights** identifying likely triggers and safe foods  
- **Personalized analysis** with customizable delay windows for symptom correlation
- **Weekly summaries** highlighting patterns and recommendations

## Core User Flow

1. **Log meals**: Capture photos with optional notes
2. **Track symptoms**: One-tap logging with intensity levels
3. **Receive insights**: Daily/weekly analysis of triggers, safe foods, and patterns

## Tech Stack

### Infrastructure
- **AWS EKS**: Kubernetes orchestration for scalable microservices
- **Terraform**: Infrastructure as Code for reproducible deployments
- **AWS S3**: Secure storage for meal photos
- **AWS RDS/DynamoDB**: Event storage (meals, symptoms, notes)
- **AWS SQS**: Asynchronous job processing queue

### AI & Analytics
- Large Language Models for ingredient extraction and food normalization
- Statistical correlation analysis for trigger identification
- Delayed symptom-food correlation modeling

## Project Structure

```
├── infra/              # Terraform infrastructure definitions
├── platform/           # Kubernetes platform configurations (Kustomize)
├── services/
│   ├── api/           # Go REST API service
│   └── worker/        # Go background worker service
└── README.md          # This file
```
