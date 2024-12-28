function Export-GitDiffArchive
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetBranch,

        [Parameter(Mandatory = $true)]
        [string]$SourceBranch,

        [Parameter()]
        [string]$OutputFile = "package.zip"
    )

    process
    {
        try
        {
            $currentBranch = git rev-parse --abbrev-ref HEAD
            if ($currentBranch -ne $SourceBranch)
            {
                git checkout $SourceBranch
            }

            $changedFiles = git diff --name-only "$TargetBranch..$SourceBranch" --diff-filter=d

            if (-not $changedFiles)
            {
                Write-Warning "No changes found between $SourceBranch and $TargetBranch"
                return
            }

            if ($PSCmdlet.ShouldProcess($OutputFile, "Create Git archive"))
            {
                git archive --output=$OutputFile $SourceBranch $changedFiles
                Write-Information "Archive created: $OutputFile" -InformationAction Continue

                if ($PSCmdlet.ShouldContinue("Do you want to import the changes to the current directory?", "Import Changes"))
                {
                    Expand-GitDiffArchive -OutputFile $OutputFile
                }
            }
        } catch
        {
            Write-Error "An error occurred during Git diff archive: $_"
        } finally
        {
            if ($currentBranch -ne $SourceBranch)
            {
                git checkout $currentBranch
            }
        }
    }
}

function Expand-GitDiffArchive
{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )

    process
    {
        if (-not (Test-Path $OutputFile))
        {
            Write-Warning "Archive file not found: $OutputFile"
            return
        }

        $tempPath = "temp_changes"

        try
        {
            if ($PSCmdlet.ShouldProcess($OutputFile, "Expand archive"))
            {
                Expand-Archive -Path $OutputFile -DestinationPath $tempPath -Force

                Get-ChildItem -Path $tempPath -Force | Copy-Item -Destination . -Recurse -Force
                Write-Information "Successfully expanded $OutputFile to current directory" -InformationAction Continue

                if ($PSCmdlet.ShouldContinue("Do you want to remove the archive file?", "Remove Archive"))
                {
                    Remove-Item -Path $OutputFile -Force
                    Write-Information "Removed archive file: $OutputFile" -InformationAction Continue
                }
            }
        } catch
        {
            Write-Error "An error occurred during archive import: $_"
        } finally
        {
            if (Test-Path $tempPath)
            {
                Remove-Item -Path $tempPath -Recurse -Force
            }
        }
    }
}
