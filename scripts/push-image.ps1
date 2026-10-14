<#
.SYNOPSIS
    Construit l'image Docker de ton application et la pousse dans le dépôt ECR d'un environnement.

.DESCRIPTION
    L'environnement doit déjà être déployé (deploy.ps1) : le script lit l'URL du dépôt ECR
    dans ses outputs. Les tags sont immuables : utilise un nouveau tag à chaque version.

    L'application doit écouter sur le port 8080, répondre 2xx/3xx sur « / » et n'écrire que dans /tmp.

.PARAMETER Tag
    Version de l'image (ex. 1.0.0).

.PARAMETER Path
    Dossier qui contient le Dockerfile de l'application.

.PARAMETER Environment
    Environnement cible : dev (par défaut) ou prod.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\push-image.ps1 -Tag 1.0.0 -Path C:\chemin\mon-app
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$')]
    [string] $Tag,

    [Parameter(Mandatory = $true)]
    [string] $Path,

    [ValidateSet('dev', 'prod')]
    [string] $Environment = 'dev'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$EnvDir = Join-Path $RootDir "environments\$Environment"

Write-Step 'Vérification des prérequis (rien ne sera installé)'
$null = Assert-Prerequisites -Tools @('terraform', 'aws', 'docker')
if (-not (Test-Path (Join-Path $Path 'Dockerfile'))) {
    throw "Aucun Dockerfile dans $Path."
}

$ecrUrl = & terraform "-chdir=$EnvDir" output -raw ecr_repository_url
if ($LASTEXITCODE -ne 0 -or -not $ecrUrl) {
    throw "Dépôt ECR introuvable : déploie d'abord l'environnement avec deploy.ps1."
}
$registry = $ecrUrl.Split('/')[0]          # <compte>.dkr.ecr.<region>.amazonaws.com
$region = $registry.Split('.')[3]
$image = "${ecrUrl}:$Tag"

Write-Step "Connexion au registre $registry"
& aws ecr get-login-password --region $region | & docker login --username AWS --password-stdin $registry
if ($LASTEXITCODE -ne 0) { throw 'La connexion à ECR a échoué (Docker Desktop est-il démarré ?).' }

Write-Step "Construction de $image"
& docker build -t $image $Path
if ($LASTEXITCODE -ne 0) { throw 'La construction de l''image a échoué.' }

Write-Step "Envoi de $image"
& docker push $image
if ($LASTEXITCODE -ne 0) { throw "L'envoi a échoué (le tag $Tag existe peut-être déjà : les tags sont immuables)." }

Write-Step 'Terminé'
Write-Host "Mets cette ligne dans environments\$Environment\terraform.tfvars :" -ForegroundColor Green
Write-Host "  container_image = `"$image`""
Write-Host "Puis : powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Environment $Environment -SkipBootstrap"
