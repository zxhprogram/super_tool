@echo off
cd /d "%~dp0"
set CGO_ENABLED=1
go mod tidy
if %errorlevel% neq 0 (
    echo go mod tidy failed!
    exit /b 1
)
go build -buildmode=c-shared -o super_tool_plugin.dll
if %errorlevel% neq 0 (
    echo Build failed!
    exit /b 1
)
echo Build succeeded: super_tool_plugin.dll
