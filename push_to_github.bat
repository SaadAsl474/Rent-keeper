@echo off
echo ========================================================
echo     Pushing RentKeeper to GitHub
echo ========================================================
echo.
cd /d "%~dp0"
git remote set-url origin https://github.com/SaadAsl474/Rent-keeper.git
echo Remote configured:
git remote -v
echo.
echo Configuring git for slow connection...
git config http.postBuffer 524288000
git config http.lowSpeedLimit 0
git config http.lowSpeedTime 999999
echo.
echo Pushing commits to branch 'master'...
git push -u origin master
echo.
if %errorlevel% equ 0 (
    echo ========================================================
    echo  SUCCESS: Code pushed to GitHub successfully!
    echo  View at: https://github.com/SaadAsl474/Rent-keeper
    echo ========================================================
) else (
    echo.
    echo --------------------------------------------------------
    echo  Push failed. If prompted, enter your GitHub Username
    echo  and Personal Access Token (PAT).
    echo  Generate token at: https://github.com/settings/tokens
    echo --------------------------------------------------------
)
pause
