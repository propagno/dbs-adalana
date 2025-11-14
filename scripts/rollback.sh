#!/bin/bash

# Script de rollback do banco de dados
# Uso: ./scripts/rollback.sh [dev|staging|prod] [count|tag]

set -e

ENVIRONMENT=${1:-dev}
ROLLBACK_TYPE=${2:-count}
ROLLBACK_VALUE=${3:-1}

echo "🔄 Iniciando rollback no ambiente: $ENVIRONMENT"

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
        DB_PASSWORD=${DB_PASSWORD_DEV:-YourStrong@Passw0rd}
        DB_PORT=1433
        ;;
    staging)
        DB_SERVICE="db-staging"
        LIQUIBASE_SERVICE="liquibase-staging"
        DB_NAME=${DB_NAME_STAGING:-propagno_db_staging}
        DB_PASSWORD=${DB_PASSWORD_STAGING:-YourStrong@Passw0rd}
        DB_PORT=1434
        ;;
    prod)
        DB_SERVICE="db-prod"
        LIQUIBASE_SERVICE="liquibase-prod"
        DB_NAME=${DB_NAME_PROD:-propagno_db_prod}
        DB_PASSWORD=${DB_PASSWORD_PROD:-YourStrong@Passw0rd}
        DB_PORT=1435
        ;;
    *)
        echo "❌ Ambiente inválido: $ENVIRONMENT"
        echo "Uso: ./scripts/rollback.sh [dev|staging|prod] [count|tag] [value]"
        exit 1
        ;;
esac

# Verifica se o banco está rodando
if ! docker-compose ps "$DB_SERVICE" | grep -q "Up"; then
    echo "❌ Banco de dados não está rodando. Execute ./scripts/init.sh primeiro."
    exit 1
fi

echo "📋 Histórico de changesets antes do rollback:"
docker run --rm \
    --network db-propagno-network \
    -v "$(pwd)/liquibase:/liquibase/changelog" \
    liquibase/liquibase:latest \
    --changelog-file=/liquibase/changelog/changelog/db.changelog-master.xml \
    --url="jdbc:sqlserver://$DB_SERVICE:$DB_PORT;databaseName=$DB_NAME;encrypt=true;trustServerCertificate=true" \
    --username=sa \
    --password="$DB_PASSWORD" \
    history

echo ""
echo "⚠️  ATENÇÃO: Você está prestes a fazer rollback no ambiente $ENVIRONMENT"
echo "Tipo: $ROLLBACK_TYPE"
echo "Valor: $ROLLBACK_VALUE"
read -p "Deseja continuar? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Rollback cancelado"
    exit 0
fi

# Executa rollback
if [ "$ROLLBACK_TYPE" = "count" ]; then
    echo "🔄 Executando rollback de $ROLLBACK_VALUE changeset(s)..."
    docker run --rm \
        --network db-propagno-network \
        -v "$(pwd)/liquibase:/liquibase/changelog" \
        liquibase/liquibase:latest \
        --changelog-file=/liquibase/changelog/changelog/db.changelog-master.xml \
        --url="jdbc:sqlserver://$DB_SERVICE:$DB_PORT;databaseName=$DB_NAME;encrypt=true;trustServerCertificate=true" \
        --username=sa \
        --password="$DB_PASSWORD" \
        rollback-count "$ROLLBACK_VALUE"
elif [ "$ROLLBACK_TYPE" = "tag" ]; then
    echo "🔄 Executando rollback para tag: $ROLLBACK_VALUE"
    docker run --rm \
        --network db-propagno-network \
        -v "$(pwd)/liquibase:/liquibase/changelog" \
        liquibase/liquibase:latest \
        --changelog-file=/liquibase/changelog/changelog/db.changelog-master.xml \
        --url="jdbc:sqlserver://$DB_SERVICE:$DB_PORT;databaseName=$DB_NAME;encrypt=true;trustServerCertificate=true" \
        --username=sa \
        --password="$DB_PASSWORD" \
        rollback "$ROLLBACK_VALUE"
else
    echo "❌ Tipo de rollback inválido: $ROLLBACK_TYPE"
    echo "Use 'count' ou 'tag'"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "✅ Rollback concluído com sucesso!"
    echo ""
    echo "📋 Histórico de changesets após rollback:"
    docker run --rm \
        --network db-propagno-network \
        -v "$(pwd)/liquibase:/liquibase/changelog" \
        liquibase/liquibase:latest \
        --changelog-file=/liquibase/changelog/changelog/db.changelog-master.xml \
        --url="jdbc:sqlserver://$DB_SERVICE:$DB_PORT;databaseName=$DB_NAME;encrypt=true;trustServerCertificate=true" \
        --username=sa \
        --password="$DB_PASSWORD" \
        history
else
    echo "❌ Erro ao executar rollback"
    exit 1
fi

