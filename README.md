# 🗄️ dbs-adalana - Repositório de Banco de Dados

Repositório dedicado para gerenciamento do banco de dados SQL Server do projeto Adalana com Liquibase para migrations.

## 📋 Características

- ✅ **SQL Server 2022** em containers Docker
- ✅ **Liquibase** para gerenciamento de migrations
- ✅ **Scripts de inicialização** e rollback
- ✅ **CI/CD pipelines** para dev, staging e produção
- ✅ **Ambientes separados** (dev, staging, prod)
- ✅ **Health checks** automáticos

## 🏗️ Estrutura

```
dbs-adalana/
├── docker-compose.yml          # Configuração Docker para todos os ambientes
├── liquibase/
│   └── changelog/
│       ├── db.changelog-master.xml  # Master changelog
│       └── V20241114_*.xml          # Migrations Adalana
├── scripts/
│   ├── init.sh                 # Script de inicialização
│   ├── rollback.sh             # Script de rollback
│   └── generate-migration.sh   # Gerar migration a partir de SQL
├── sql/                        # Scripts SQL para gerar migrations
└── .github/
    └── workflows/              # Pipelines CI/CD
```

## 🚀 Início Rápido

### Pré-requisitos

- Docker e Docker Compose instalados
- Git

### Configuração Inicial

1. **Clone o repositório:**
```bash
git clone git@github.com:propagno/dbs-adalana.git
cd dbs-adalana
```

2. **Configure as variáveis de ambiente:**
```bash
cp .env.example .env.dev
# Edite .env.dev com suas configurações
```

3. **Inicialize o banco de dados:**
```bash
chmod +x scripts/*.sh
./scripts/init.sh dev
```

## 📖 Uso

### Inicialização

Inicializa o banco de dados e executa todas as migrations:

```bash
# Desenvolvimento
./scripts/init.sh dev

# Staging
./scripts/init.sh staging

# Produção
./scripts/init.sh prod
```

### Rollback

Reverte migrations do banco de dados:

```bash
# Rollback por quantidade de changesets
./scripts/rollback.sh dev count 1

# Rollback para uma tag específica
./scripts/rollback.sh dev tag v1.0.0
```

### Docker Compose

Você também pode usar docker-compose diretamente:

```bash
# Iniciar apenas o banco de desenvolvimento
docker-compose up -d db-dev

# Executar migrations
docker-compose up liquibase-dev

# Ver logs
docker-compose logs -f db-dev

# Parar tudo
docker-compose down
```

## 🔧 Configuração

### Variáveis de Ambiente

Crie arquivos `.env.dev`, `.env.staging`, `.env.prod` com:

```bash
DB_PASSWORD_DEV=YourStrong@Passw0rd
DB_NAME_DEV=adalana_db
```

### Portas

- **Dev**: `1433`
- **Staging**: `1434`
- **Prod**: `1435`

### Conexão

**JDBC URL:**
```
jdbc:sqlserver://localhost:1433;databaseName=adalana_db;encrypt=true;trustServerCertificate=true
```

**Credenciais padrão:**
- Usuário: `sa`
- Senha: Configurada em `.env.*`

## 📝 Migrations com Liquibase

### Método 1: Gerar Migration a partir de SQL (Recomendado)

**Para adicionar novas tabelas sem comprometer dados existentes:**

1. **Crie um script SQL** em `sql/`:
```sql
-- sql/users_table.sql
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[users]') AND type in (N'U'))
BEGIN
    CREATE TABLE users (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        username NVARCHAR(100) NOT NULL,
        email NVARCHAR(255) NOT NULL,
        created_at DATETIME2 DEFAULT GETDATE() NOT NULL
    );
END
```

2. **Gere a migration automaticamente:**

**Windows:**
```powershell
.\scripts\generate-migration-from-sql.ps1 -MigrationName "Add_users_table" -SqlFile "sql\users_table.sql"
```

**Linux/Mac:**
```bash
./scripts/generate-migration.sh "Add_users_table" "sql/users_table.sql"
```

3. **Commit e push** → A pipeline executa automaticamente!

**⚠️ IMPORTANTE:**
- Sempre use `IF NOT EXISTS` para evitar erros se a tabela já existir
- Isso garante que a migration seja idempotente (pode ser executada múltiplas vezes)
- Os dados existentes não serão afetados

### Método 2: Criar Migration Manualmente

1. Crie um novo arquivo XML em `liquibase/changelog/`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

    <changeSet id="2" author="seu-nome">
        <comment>Descrição da migration</comment>
        
        <createTable tableName="nova_tabela">
            <column name="id" type="BIGINT" autoIncrement="true">
                <constraints primaryKey="true" nullable="false"/>
            </column>
            <column name="nome" type="NVARCHAR(255)">
                <constraints nullable="false"/>
            </column>
        </createTable>
    </changeSet>

</databaseChangeLog>
```

2. Inclua no `db.changelog-master.xml`:
```xml
<include file="V2__Nova_tabela.xml" relativeToChangelogFile="true"/>
```

### Boas Práticas

**✅ Para adicionar colunas:**
```sql
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[table_name]') AND name = 'column_name')
BEGIN
    ALTER TABLE table_name ADD column_name NVARCHAR(255);
END
```

**✅ Para adicionar índices:**
```sql
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'idx_table_column')
BEGIN
    CREATE INDEX idx_table_column ON table_name(column_name);
END
```

**❌ Evite:**
- `DROP TABLE` (destrói dados)
- `TRUNCATE TABLE` (remove todos os dados)
- `ALTER TABLE ... DROP COLUMN` (remove dados)
- Migrations sem `IF NOT EXISTS` (podem falhar)

## 🔄 CI/CD

### Desenvolvimento

- **Trigger**: Push para branch `develop`
- **Ações**: Valida migrations e executa deploy automático

### Staging

- **Trigger**: Push para branch `main`
- **Ações**: Valida, faz security scan e executa deploy

### Produção

- **Trigger**: Tag `v*.*.*` ou workflow manual
- **Ações**: Valida, security scan, backup e deploy
- **Confirmação**: Requer confirmação manual

### Rollback via GitHub Actions

1. Vá em **Actions > Database Rollback**
2. Clique em **Run workflow**
3. Selecione ambiente, tipo e valor do rollback

## 🔗 Integração com Serviços

Para conectar um serviço a este banco de dados:

```yaml
# docker-compose.yml do serviço
services:
  app:
    environment:
      - SPRING_DATASOURCE_URL=jdbc:sqlserver://db-dev:1433;databaseName=adalana_db;encrypt=true;trustServerCertificate=true
      - SPRING_DATASOURCE_USERNAME=sa
      - SPRING_DATASOURCE_PASSWORD=YourStrong@Passw0rd
    networks:
      - db-propagno-network  # Use a mesma network
```

Ou conecte via host externo:

```yaml
- SPRING_DATASOURCE_URL=jdbc:sqlserver://localhost:1433;databaseName=adalana_db;encrypt=true;trustServerCertificate=true
```

## 🛠️ Troubleshooting

### Banco não inicia

```bash
# Ver logs
docker-compose logs db-dev

# Verificar saúde
docker-compose ps
```

### Migration falha

```bash
# Ver histórico
docker run --rm \
  --network db-propagno-network \
  -v "$(pwd)/liquibase:/liquibase/changelog" \
  liquibase/liquibase:latest \
  --changelog-file=/liquibase/changelog/db.changelog-master.xml \
  --url="jdbc:sqlserver://db-dev:1433;databaseName=adalana_db;encrypt=true;trustServerCertificate=true" \
  --username=sa \
  --password="YourStrong@Passw0rd" \
  history
```

### Reset completo

```bash
# ⚠️ ATENÇÃO: Isso apaga todos os dados!
docker-compose down -v
docker-compose up -d db-dev
./scripts/init.sh dev
```

### Erro: "Table already exists"

**Causa:** Migration foi executada antes ou tabela já existe.

**Solução:** Adicione `IF NOT EXISTS` no seu script SQL.

### Erro: "Changeset already executed"

**Causa:** Migration já foi aplicada.

**Solução:** Crie uma nova migration com novo ID/timestamp.

## 📚 Contribuindo

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/minha-feature`
3. Crie o script SQL em `sql/`
4. Gere a migration usando os scripts
5. Commit: `git commit -m "feat: adiciona tabela X"`
6. Push: `git push origin feature/minha-feature`
7. Abra um Pull Request

**Checklist antes de PR:**
- [ ] Script SQL usa `IF NOT EXISTS`
- [ ] Migration gerada corretamente
- [ ] Testado localmente
- [ ] Adicionado ao `db.changelog-master.xml`
- [ ] Commit segue a convenção

## 📚 Recursos

- [Liquibase Documentation](https://docs.liquibase.com/)
- [SQL Server Docker](https://hub.docker.com/_/microsoft-mssql-server)
- [Liquibase Docker](https://hub.docker.com/r/liquibase/liquibase)

## 📄 Licença

Este repositório faz parte da infraestrutura Propagno.

---

**Desenvolvido para Propagno** 🚀
