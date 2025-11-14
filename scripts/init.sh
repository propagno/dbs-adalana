#!/bin/bash

# Script de inicialização do banco de dados
# Uso: ./scripts/init.sh [dev|staging|prod]

set -e

ENVIRONMENT=${1:-dev}

echo "🚀 Iniciando banco de dados no ambiente: $ENVIRONMENT"

# Carrega variáveis de ambiente
if [ -f ".env.${ENVIRONMENT}" ]; then
    echo "📝 Carregando variáveis de .env.${ENVIRONMENT}"
    export $(cat .env.${ENVIRONMENT} | grep -v '^#' | xargs)
fi

# Define variáveis baseadas no ambiente
case "$ENVIRONMENT" in
    dev)
        DB_SERVICE="db-dev"
        LIQUIBASE_SERVICE="liquibase-dev"
        DB_NAME=${DB_NAME_DEV:-propagno_db}
        ;;
    staging)
        DB_SERVICE="db-staging"
        LIQUIBASE_SERVICE="liquibase-staging"
        DB_NAME=${DB_NAME_STAGING:-propagno_db_staging}
        ;;
    prod)
        DB_SERVICE="db-prod"
        LIQUIBASE_SERVICE="liquibase-prod"
        DB_NAME=${DB_NAME_PROD:-propagno_db_prod}
        ;;
    *)
        echo "❌ Ambiente inválido: $ENVIRONMENT"
        echo "Uso: ./scripts/init.sh [dev|staging|prod]"
        exit 1
        ;;
esac

echo "📦 Iniciando container do banco de dados: $DB_SERVICE"
docker-compose up -d "$DB_SERVICE"

echo "⏳ Aguardando banco de dados ficar pronto..."
MAX_RETRIES=60
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if docker-compose ps "$DB_SERVICE" | grep -q "healthy"; then
        echo "✅ Banco de dados está saudável!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Tentativa $RETRY_COUNT/$MAX_RETRIES..."
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "❌ Banco de dados não ficou pronto a tempo"
    exit 1
fi

echo "🔄 Executando migrations com Liquibase..."
docker-compose up "$LIQUIBASE_SERVICE"

if [ $? -eq 0 ]; then
    echo "✅ Inicialização concluída com sucesso!"
    echo "📊 Database: $DB_NAME"
    echo "🔗 Conexão: localhost:1433 (dev) | localhost:1434 (staging) | localhost:1435 (prod)"
else
    echo "❌ Erro ao executar migrations"
    exit 1
fi

