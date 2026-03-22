# 自动请求管理员权限
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}

Write-Host "这个程序用于破除校园网的AP隔离" -ForegroundColor Red
Write-Host "`n说人话就是解决校园网中电脑不能互相通信的臭毛病" -ForegroundColor Yellow
# windows 将ps、bat、py等脚本、代码编译成exe文件
# 以管理员身份打开 PowerShell
# 运行: Install-Module ps2exe -Force
# 运行: Invoke-ps2exe "route_config.ps1" "校园网通信限制破解(右键以管理员身份运行).exe"

# 获取所有网络适配器
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
    $config = Get-NetIPConfiguration -InterfaceIndex $_.InterfaceIndex
    [PSCustomObject]@{
        Index = $_.InterfaceIndex
        Name = $_.Name
        Description = $_.InterfaceDescription
        IP = $config.IPv4Address.IPAddress
        Gateway = $config.IPv4DefaultGateway.NextHop
        Status = $_.Status
    }
}

# 显示适配器列表
Write-Host "`n所有活动的网络适配器：" -ForegroundColor Green
Write-Host "（🔍选连校园网的那个适配器！！！一般是有默认网关的那个✨）" -ForegroundColor Red


if ($adapters.Count -eq 0) {
    Write-Host "未找到任何活动的网络适配器！" -ForegroundColor Red
    Write-Host "`n按任意键退出..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

for ($i = 0; $i -lt $adapters.Count; $i++) {
    Write-Host "`n[$i] " -NoNewline -ForegroundColor Yellow
    Write-Host "$($adapters[$i].Name)" -ForegroundColor Cyan
    Write-Host "    描述: $($adapters[$i].Description)"
    Write-Host "    IP地址: $($adapters[$i].IP)"
    Write-Host "    网关🍗: " -NoNewline
    if ($adapters[$i].Gateway) {
        # Write-Host "$($adapters[$i].Gateway)" -ForegroundColor Green
        Write-Host "$($adapters[$i].Gateway) 👈选这个网络适配器🍗" -ForegroundColor Green
    } else {
        Write-Host "无默认网关" -ForegroundColor Red
    }
    Write-Host "    状态: $($adapters[$i].Status)"
}

# 用户选择
do {
    Write-Host "`n请选择要配置的网络适配器 [0-$($adapters.Count - 1)]: " -NoNewline -ForegroundColor Green
    $choice = Read-Host
} while ($choice -notmatch '^\d+$' -or [int]$choice -lt 0 -or [int]$choice -ge $adapters.Count)

$selected = $adapters[[int]$choice]

# 检查选择的适配器是否有网关
if (-not $selected.Gateway) {
    Write-Host "`n错误：选择的网络适配器没有默认网关，无法配置！" -ForegroundColor Red
    Write-Host "请选择有默认网关的网络适配器。" -ForegroundColor Yellow
    Write-Host "`n按任意键退出..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# 计算网段
$ipParts = $selected.IP.Split('.')
$networkID = "{0}.{1}.{2}.0" -f $ipParts[0], $ipParts[1], ($ipParts[2] -band 0xC0)

Write-Host "`n正在配置路由..." -ForegroundColor Green
Write-Host "选择的适配器: $($selected.Name)" -ForegroundColor Yellow
Write-Host "网关: $($selected.Gateway)" -ForegroundColor Yellow
Write-Host "网段: $networkID" -ForegroundColor Yellow

# 删除直连路由
Write-Host "`n删除直连路由..." -ForegroundColor Yellow
route delete $networkID mask 255.255.192.0

# 添加网关路由
Write-Host "添加网关路由..." -ForegroundColor Yellow
route -p add $networkID mask 255.255.192.0 $selected.Gateway

Write-Host "`n配置完成！" -ForegroundColor Green
Write-Host "`n按任意键退出..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
