# Function to install Python
function Install-Python {
    Write-Host "Python not found. Installing Python..."
    $pythonInstallerUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    $pythonInstaller = "$env:TEMP\python-installer.exe"
    Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $pythonInstaller
    Start-Process -FilePath $pythonInstaller -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait
    Remove-Item -Path $pythonInstaller
    Write-Host "Python installed successfully."
    Write-Host "Please reopen PowerShell for the path changes to take effect, then rerun the script."
    Read-Host -Prompt "Press Enter to exit"
    exit 0
}

# Function to check for Python installation
function Get-PythonPath {
    $pythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
    if ($pythonExe -and $pythonExe -like "*Microsoft\WindowsApps*") {
        return $null
    }
    return $pythonExe
}

# Function to check if pip is installed and install it if missing
function Install-Pip {
    Write-Host "pip not found. Installing pip..."
    python -m ensurepip --upgrade
    if ($?) {
        python -m pip install --upgrade pip
        Write-Host "pip installed successfully."
    } else {
        Write-Host "Error installing pip."
        exit 1
    }
}

# Function to install SISOU using pip
function Install-SISOU {
    Write-Host "Installing Super ISO Updater (SISOU)..."
    python -m pip install sisou
}

# Function to detect Ventoy drive or prompt the user to select one
function Get-VentoyDrive {
    $ventoyDrive = Get-WmiObject Win32_Volume | Where-Object { $_.Label -eq 'Ventoy' } | Select-Object -ExpandProperty DriveLetter
    if (-not $ventoyDrive) {
        $ventoyDrive = Read-Host "Ventoy drive not detected. Please enter the drive letter (e.g., E:)"
    }
    return $ventoyDrive
}

# Main logic

# Step 1: Check for Python and install if not found
$pythonPath = Get-PythonPath
if (-not $pythonPath) {
    Install-Python
    exit 0
} else {
    Write-Host "Python is already installed at $pythonPath."
}

# Step 2: Check for pip and install if not found
$pipPath = Get-Command pip -ErrorAction SilentlyContinue
if (-not $pipPath) {
    Install-Pip
} else {
    Write-Host "pip is already installed."
}

# Step 3: Check if SISOU is installed and install if missing
$sisouInstalled = python -m pip show sisou 2>&1 | Select-String 'Name: sisou'
if (-not $sisouInstalled) {
    Install-SISOU
} else {
    Write-Host "SISOU is already installed."
}

# Step 4: Detect or prompt for Ventoy drive
$ventoyDrive = Get-VentoyDrive
if (-not $ventoyDrive) {
    Write-Host "No Ventoy drive selected. Exiting..."
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

# Step 5: Run SISOU on the Ventoy drive
Write-Host "Running SISOU on drive $ventoyDrive..."
python -m sisou $ventoyDrive

# Pause after finishing ISO update process
Write-Host "ISO update process completed."
Read-Host -Prompt "Press Enter to exit"
