# Script PowerShell para gerar migration do Liquibase a partir de um script SQL
# Uso: .\scripts\generate-migration-from-sql.ps1 -MigrationName "Add_user_table" -SqlFile "sql\user_table.sql"

param(
    [Parameter(Mandatory=$true)]
    [string]$MigrationName,
    
    [Parameter(Mandatory=$true)]
    [string]$SqlFile
)

$ErrorActionPreference = "Stop"

# Valida se o arquivo SQL existe
if (-not (Test-Path $SqlFile)) {
    Write-Host "❌ Arquivo SQL não encontrado: $SqlFile" -ForegroundColor Red
    exit 1
}

$MigrationDir = "liquibase\changelog"
$MasterFile = "$MigrationDir\db.changelog-master.xml"

# Gera nome do arquivo de migration baseado no timestamp
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$MigrationFile = "$MigrationDir\V${Timestamp}__${MigrationName}.xml"

# Conta quantas migrations já existem
$ExistingMigrations = Get-ChildItem -Path "$MigrationDir" -Filter "V*.xml" -ErrorAction SilentlyContinue
$ChangesetCount = if ($ExistingMigrations) { $ExistingMigrations.Count } else { 0 }
$NextChangesetId = $ChangesetCount + 1

Write-Host "📝 Gerando migration: $MigrationFile" -ForegroundColor Cyan
Write-Host "📊 Changeset ID: $NextChangesetId" -ForegroundColor Cyan

# Lê o conteúdo do arquivo SQL
$SqlContent = Get-Content $SqlFile -Raw

# Gera o arquivo XML do Liquibase
$XmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
    http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.20.xsd">

    <changeSet id="$NextChangesetId" author="propagno">
        <comment>$MigrationName</comment>
        
        <!-- SQL gerado a partir do modelo físico -->
        <sql>
            $SqlContent
        </sql>
    </changeSet>

</databaseChangeLog>
"@

$XmlContent | Out-File -FilePath $MigrationFile -Encoding UTF8 -NoNewline
Write-Host "✅ Migration criada: $MigrationFile" -ForegroundColor Green

# Adiciona ao changelog master
$MasterContent = Get-Content $MasterFile -Raw
$MigrationFileName = Split-Path $MigrationFile -Leaf

if ($MasterContent -notmatch [regex]::Escape($MigrationFileName)) {
    # Adiciona o include antes de </databaseChangeLog>
    $IncludeLine = "        <include file=`"$MigrationFileName`" relativeToChangelogFile=`"true`"/>"
    $MasterContent = $MasterContent -replace '(</databaseChangeLog>)', "$IncludeLine`r`n`r`n    $1"
    $MasterContent | Out-File -FilePath $MasterFile -Encoding UTF8 -NoNewline
    Write-Host "✅ Migration adicionada ao changelog master" -ForegroundColor Green
} else {
    Write-Host "⚠️  Migration já existe no changelog master" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Migration gerada com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Cyan
Write-Host "  1. Revise o arquivo: $MigrationFile"
Write-Host "  2. Commit e push para executar na pipeline"
Write-Host "  3. Ou execute localmente: docker-compose up liquibase-dev"

