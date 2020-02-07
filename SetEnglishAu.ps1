#This script will remove English US from the Windows language list and then force English AU as default.
$LangList = Get-WinUserLanguageList
$MarkedLang = $LangList | where LanguageTag -eq "en-US"
$LangList.Remove($MarkedLang)
Set-WinUserLanguageList en-AU -Force
