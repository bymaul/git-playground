# Aliases
Set-Alias -Name nah -Value Reset-GitRepository
Set-Alias -Name gcp -Value Invoke-GitPush
Set-Alias -Name glog -Value Get-GitLog
Set-Alias -Name gad -Value Export-GitDiffArchive

# Functions
function Reset-GitRepository
{
	git reset --hard
	git clean -df
}

function Get-GitLog
{
	git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
}

function Invoke-GitPush
{
	param (
		[string]$CommitMessage
	)

	$untrackedFiles = git ls-files --others --exclude-standard

	if ($untrackedFiles)
	{
		Write-Host "Untracked files detected. Adding them to staging."
		git add --all
	} else
	{
		Write-Host "No untracked files detected. Proceeding with patch stage."
		git add -p
	}


	git $($CommitMessage ? 'commit -m "$CommitMessage"' : "commit")
	git push
}
