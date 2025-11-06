#!/bin/bash
# Test de l'API categories

TOKEN="eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwOi8vMTI3LjAuMC4xOjgwODAiLCJhdWQiOiJodHRwOi8vMTI3LjAuMC4xOjgwODAiLCJpYXQiOjE3MzA4MjM5OTksImV4cCI6OTk5OTk5OTk5OSwidXNlcl9pZCI6MX0.m1JaH5M4G0rLsm-XPcWdq8teSAQxXQr44l-2WEGNpxY"

echo "Test de POST /categories/initialize-defaults"
curl -X POST http://127.0.0.1:8080/categories/initialize-defaults \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -s

echo ""
echo "Statut HTTP : $?"