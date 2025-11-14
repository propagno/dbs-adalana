#!/bin/bash

# Script de setup automatizado para desenvolvedores
# Uso: ./scripts/setup.sh

set -e

echo "🚀 Configurando ambiente de desenvolvimento..."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar pré-requisitos
echo ""
echo "📋 Verificando pré-requisitos..."
MISSING=0

if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker instalado${NC}"
else
    echo -e "${RED}❌ Docker não encontrado${NC}"
    MISSING=1
fi

if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✅ Docker Compose instalado${NC}"
else
    echo -e "${RED}❌ Docker Compose não encontrado${NC}"
    MISSING=1
fi

if [ $MISSING -eq 1 ]; then
    echo -e "${RED}❌ Alguns pré-requisitos estão faltando. Por favor, instale-os antes de continuar.${NC}"
    exit 1
fi

# Criar arquivo .env se não existir
echo ""
echo "📝 Configurando variáveis de ambiente..."
if [ ! -f ".env.dev" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env.dev
        echo -e "${GREEN}✅ Arquivo .env.dev criado a partir de .env.example${NC}"
        echo -e "${YELLOW}⚠️  Por favor, edite .env.dev com suas configurações${NC}"
    else
        echo -e "${YELLOW}⚠️  Arquivo .env.example não encontrado${NC}"
    fi
else
    echo -e "${GREEN}✅ Arquivo .env.dev já existe${NC}"
fi

# Verificar se o diretório sql existe
echo ""
echo "📁 Verificando estrutura..."
if [ ! -d "sql" ]; then
    mkdir -p sql
    echo -e "${GREEN}✅ Diretório sql criado${NC}"
fi

# Verificar permissões dos scripts
echo ""
echo "🔐 Configurando permissões..."
chmod +x scripts/*.sh 2>/dev/null || echo -e "${YELLOW}⚠️  Não foi possível configurar permissões (Windows)${NC}"

# Resumo
echo ""
echo -e "${GREEN}✅ Setup concluído!${NC}"
echo ""
echo "📋 Próximos passos:"
echo "  1. Edite .env.dev com suas configurações"
echo "  2. Inicie o banco de dados:"
echo "     ./scripts/init.sh dev"
echo "  3. Adicione novas tabelas (se necessário):"
echo "     ./scripts/generate-migration.sh \"Nome_Migration\" \"sql/arquivo.sql\""
echo ""
echo "📚 Documentação:"
echo "  - Quick Start: QUICKSTART.md"
echo "  - README: README.md"
echo "  - Como Adicionar Tabelas: HOW-TO-ADD-TABLES.md"
echo ""

