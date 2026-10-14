<#
.SYNOPSIS
    Supprime un environnement (dev ou prod) pour arrêter les coûts AWS.

.DESCRIPTION
    Planifie la destruction, l'affiche, puis demande de taper le nom de l'environnement
    pour confirmer. Le backend du state (bootstrap) est conservé : il coûte environ 1 USD/mois.

    En prod, la protection contre la suppression bloque la destruction : passer d'abord
    deletion_protection = false dans environments/prod/terraform.tfvars et relancer deploy.ps1.

.PARAMETER Environment
    Environnement à supprimer : dev (par défaut) ou prod.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\destroy.ps1
#>
[CmdletBinding()]
param(
    [ValidateSet('dev', 'prod')]
    [string] $Environment = 'dev'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$EnvDir = Join-Path $RootDir "environments\$Environment"

Write-Step 'Vérification des prérequis (rien ne sera installé)'
$null = Assert-Prerequisites
Assert-NoPlaceholder (Join-Path $EnvDir 'backend.hcl')

if ($Environment -eq 'prod') {
    Write-Host 'En prod, deletion_protection doit valoir false (puis deploy.ps1) avant la destruction.' -ForegroundColor Yellow
}

Write-Step "Destruction de l'environnement $Environment"
Invoke-PlanAndApply -Directory $EnvDir -Label $Environment -Destroy -ConfirmWord $Environment `
    -InitArguments @('-reconfigure', '-backend-config=backend.hcl')

Write-Step 'Terminé'
Write-Host "L'environnement $Environment est supprimé. Le backend (bootstrap) est conservé." -ForegroundColor Green
