# Fonctions partagées par les scripts de déploiement (chargées avec « . »).
# Compatible Windows PowerShell 5.1 et PowerShell 7. N'installe rien.

$RootDir = Split-Path -Parent $PSScriptRoot

function Write-Step {
    param([string] $Message)
    Write-Host ''
    Write-Host "==> $Message" -ForegroundColor Cyan
}

# Lance terraform et arrête le script si la commande échoue.
function Invoke-Terraform {
    param([Parameter(Mandatory = $true)] [string[]] $Arguments)
    & terraform @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "La commande 'terraform $($Arguments -join ' ')' a échoué (code $LASTEXITCODE)."
    }
}

# Vérifie les outils et les identifiants AWS. Renvoie le numéro de compte.
function Assert-Prerequisites {
    param([string[]] $Tools = @('terraform', 'aws'))
    foreach ($tool in $Tools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            throw "'$tool' est introuvable. Installe-le, rouvre le terminal, puis relance le script."
        }
    }
    $account = & aws sts get-caller-identity --query Account --output text
    if ($LASTEXITCODE -ne 0 -or -not $account) {
        throw "Aucun identifiant AWS valide. Lance 'aws configure', puis relance le script."
    }
    $account = "$account".Trim()
    Write-Host "Compte AWS utilisé : $account" -ForegroundColor Yellow
    return $account
}

# Refuse de continuer si un fichier contient encore des valeurs d'exemple (<ACCOUNT_ID>...).
function Assert-NoPlaceholder {
    param([Parameter(Mandatory = $true)] [string] $Path)
    if (Select-String -Path $Path -Pattern '<[A-Z_]+>' -CaseSensitive -Quiet) {
        throw "Le fichier $Path contient encore des valeurs d'exemple (<...>). Remplis-les, puis relance."
    }
}

# init + plan, affiche le plan, demande confirmation, puis applique exactement ce plan.
function Invoke-PlanAndApply {
    param(
        [Parameter(Mandatory = $true)] [string] $Directory,
        [Parameter(Mandatory = $true)] [string] $Label,
        [string[]] $InitArguments = @(),
        [string] $ConfirmWord = 'oui',
        [switch] $Destroy
    )
    Push-Location $Directory
    try {
        Invoke-Terraform (@('init', '-input=false') + $InitArguments)

        $planArguments = @('plan', '-input=false', '-out=tfplan', '-detailed-exitcode')
        if ($Destroy) { $planArguments += '-destroy' }
        & terraform @planArguments
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$Label : rien à changer." -ForegroundColor Green
            return
        }
        if ($LASTEXITCODE -ne 2) {
            throw "Le plan de $Label a échoué (code $LASTEXITCODE)."
        }

        $action = 'appliquer ce plan'
        if ($Destroy) { $action = 'SUPPRIMER ces ressources' }
        $answer = Read-Host "Pour $action ($Label), tape '$ConfirmWord'"
        if ($answer -ne $ConfirmWord) {
            throw "Opération annulée : rien n'a été modifié sur AWS."
        }

        Invoke-Terraform @('apply', '-input=false', 'tfplan')
    }
    finally {
        Remove-Item -Force -ErrorAction SilentlyContinue 'tfplan'
        Pop-Location
    }
}

# Écrit backend.hcl (sans BOM, requis par Terraform) à partir de la sortie de bootstrap.
function Write-BackendConfig {
    param(
        [Parameter(Mandatory = $true)] [string] $BootstrapDirectory,
        [Parameter(Mandatory = $true)] [string[]] $Targets
    )
    $lines = & terraform "-chdir=$BootstrapDirectory" output -raw backend_config
    if ($LASTEXITCODE -ne 0) {
        throw "Impossible de lire la sortie backend_config de bootstrap."
    }
    $header = '# Généré par scripts/deploy.ps1 à partir de « terraform output backend_config » (bootstrap).'
    $body = ($lines | ForEach-Object { $_.TrimEnd() } | Where-Object { $_ -ne '' }) -join "`n"
    $content = "$header`n$body`n"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    foreach ($target in $Targets) {
        [System.IO.File]::WriteAllText($target, $content, $utf8NoBom)
        Write-Host "Écrit : $target"
    }
}
