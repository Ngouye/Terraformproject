<#
.SYNOPSIS
    Déploie le projet sur AWS : backend du state (bootstrap), puis l'environnement choisi.

.DESCRIPTION
    1. Vérifie que Terraform, l'AWS CLI et des identifiants AWS valides sont présents (n'installe rien).
    2. Crée ou met à jour la stack bootstrap (S3 + DynamoDB + KMS), après confirmation.
    3. Écrit backend.hcl dans environments/dev et environments/prod à partir des sorties de bootstrap.
    4. Planifie l'environnement, demande confirmation, puis l'applique et affiche l'URL.

    Chaque création de ressources payantes demande de taper « oui ».

.PARAMETER Environment
    Environnement à déployer : dev (par défaut) ou prod.

.PARAMETER SkipBootstrap
    Ne pas toucher à bootstrap (backend déjà créé et backend.hcl déjà rempli).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\deploy.ps1 -Environment prod -SkipBootstrap
#>
[CmdletBinding()]
param(
    [ValidateSet('dev', 'prod')]
    [string] $Environment = 'dev',

    [switch] $SkipBootstrap
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$BootstrapDir = Join-Path $RootDir 'bootstrap'
$EnvDir = Join-Path $RootDir "environments\$Environment"

Write-Step 'Vérification des prérequis (rien ne sera installé)'
$null = Assert-Prerequisites

if (-not $SkipBootstrap) {
    Write-Step 'Étape 1/3 : backend du state (bootstrap : S3 + DynamoDB + KMS)'
    Invoke-PlanAndApply -Directory $BootstrapDir -Label 'bootstrap'

    Write-Step 'Étape 2/3 : écriture de backend.hcl'
    Write-BackendConfig -BootstrapDirectory $BootstrapDir -Targets @(
        (Join-Path $RootDir 'environments\dev\backend.hcl'),
        (Join-Path $RootDir 'environments\prod\backend.hcl')
    )
}

Assert-NoPlaceholder (Join-Path $EnvDir 'backend.hcl')
Assert-NoPlaceholder (Join-Path $EnvDir 'terraform.tfvars')

Write-Step "Étape 3/3 : environnement $Environment"
Write-Host 'Attention : les coûts AWS commencent dès la création (environ 95 USD/mois pour dev, 400 USD/mois pour prod).' -ForegroundColor Yellow
Write-Host 'Pense à lancer scripts\destroy.ps1 quand tu as terminé.' -ForegroundColor Yellow
Invoke-PlanAndApply -Directory $EnvDir -Label $Environment -InitArguments @('-reconfigure', '-backend-config=backend.hcl')

Push-Location $EnvDir
try {
    $url = & terraform output -raw app_url
    $dashboard = & terraform output -raw dashboard_url
}
finally {
    Pop-Location
}

Write-Step 'Terminé'
Write-Host "Application : $url" -ForegroundColor Green
Write-Host "Dashboard   : $dashboard"
Write-Host 'Si la page renvoie une erreur 503, attends 2 à 3 minutes (démarrage des conteneurs).'
Write-Host "Pour tout supprimer : powershell -ExecutionPolicy Bypass -File .\scripts\destroy.ps1 -Environment $Environment"
