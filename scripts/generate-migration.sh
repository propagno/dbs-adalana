#!/bin/bash

# Script para gerar migration do Liquibase a partir de um script SQL
# Uso: ./scripts/generate-migration.sh <nome-da-migration> <arquivo.sql>
# Exemplo: ./scripts/generate-migration.sh "Add_user_table" "sql/user_table.sql"

set -e

if [ $# -lt 2 ]; then
    echo "❌ Uso: ./scripts/generate-migration.sh <nome-da-migration> <arquivo.sql>"
    echo ""
    echo "Exemplo:"
    echo "  ./scripts/generate-migration.sh \"Add_user_table\" \"sql/user_table.sql\""
    echo ""
    echo "O script irá:"
    echo "  1. Ler o arquivo SQL fornecido"
    echo "  2. Gerar um arquivo XML do Liquibase"
    echo "  3. Adicionar ao changelog master"
    exit 1
fi

MIGRATION_NAME="$1"
SQL_FILE="$2"
MIGRATION_DIR="liquibase/changelog"
MASTER_FILE="$MIGRATION_DIR/db.changelog-master.xml"

# Valida se o arquivo SQL existe
if [ ! -f "$SQL_FILE" ]; then
    echo "❌ Arquivo SQL não encontrado: $SQL_FILE"
    exit 1
fi

# Gera nome do arquivo de migration baseado no timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
MIGRATION_FILE="$MIGRATION_DIR/V${TIMESTAMP}__${MIGRATION_NAME}.xml"

# Conta quantas migrations já existem para gerar o ID do changeset
CHANGESET_COUNT=$(find "$MIGRATION_DIR" -name "V*.xml" | wc -l | tr -d ' ')
NEXT_CHANGESET_ID=$((CHANGESET_COUNT + 1))

echo "📝 Gerando migration: $MIGRATION_FILE"
echo "📊 Changeset ID: $NEXT_CHANGESET_ID"

# Lê o conteúdo do arquivo SQL
SQL_CONTENT=$(cat "$SQL_FILE")

# Gera o arquivo XML do Liquibase
cat > "$MIGRATION_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

    <changeSet id="$NEXT_CHANGESET_ID" author="propagno">
        <comment>$MIGRATION_NAME</comment>
        
        <!-- SQL gerado a partir do modelo físico -->
        <sql>
            $SQL_CONTENT
        </sql>
    </changeSet>

</databaseChangeLog>
EOF

echo "✅ Migration criada: $MIGRATION_FILE"

# Adiciona ao changelog master
if ! grep -q "$(basename $MIGRATION_FILE)" "$MASTER_FILE"; then
    # Encontra a linha </databaseChangeLog> e adiciona o include antes
    sed -i.bak "/<\/databaseChangeLog>/i\\
        <include file=\"$(basename $MIGRATION_FILE)\" relativeToChangelogFile=\"true\"/>\\
" "$MASTER_FILE"
    rm -f "${MASTER_FILE}.bak"
    echo "✅ Migration adicionada ao changelog master"
else
    echo "⚠️  Migration já existe no changelog master"
fi

echo ""
echo "✅ Migration gerada com sucesso!"
echo ""
echo "📋 Próximos passos:"
echo "  1. Revise o arquivo: $MIGRATION_FILE"
echo "  2. Commit e push para executar na pipeline"
echo "  3. Ou execute localmente: ./scripts/init.sh dev"

