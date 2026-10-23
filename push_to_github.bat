@echo off
echo ========================================================
echo     Pushing RentKeeper to GitHub (Pocket-Ledger-App)
echo ========================================================
echo.
cd /d "%~dp0"
git remote set-url origin https://github.com/SaadAsl474/Pocket-Ledger-App.git
echo Remote configured:
git remote -v
echo.
echo Pushing commits to branch 'master'...
git push -u origin master
echo.
if %errorlevel% equ 0 (
    echo ========================================================
    echo  SUCCESS: Code pushed to GitHub successfully!
    echo  View at: https://github.com/SaadAsl474/Pocket-Ledger-App
    echo ========================================================
) else (
    echo.
    echo --------------------------------------------------------
    echo If prompted, enter your GitHub Username and Personal 
    echo Access Token (PAT).
    echo Generate token at: https://github.com/settings/tokens
    echo --------------------------------------------------------
)
pause
