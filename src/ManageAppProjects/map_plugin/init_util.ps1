# Check config path
$util_root = -join ($PSScriptRoot, '\..\..\..')
$cfg_path = -join ($util_root, '\settings.yml')
if (!(Test-Path $cfg_path))
{
    Write-Error (-join ('Config not found, path: ', $cfg_path))
    return
}

function Create-Folders-If-Not-Exist
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )
    if (!(Test-Path -Path $TargetPath))
    {
        New-Item -ItemType directory -Path $TargetPath
    }
}

function Copy-Modified-Config
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [bool]$IsAfterInstall
    )
    $original_cfg = Get-Content -Path $SourcePath -Encoding 'utf8'
    foreach ($line in $original_cfg)
    {
        if ( $line.StartsWith("    home_path:"))
        {
            $home_path = -join ($root_path, '\', $cfg.install_instance_name)
            Add-Content -Path $TargetPath -Value "    home_path: $home_path" -Encoding 'utf8'
        }
        elseif ($line.StartsWith("    home_path_src:"))
        {
            $home_path_src = -join ($root_path, '\', $cfg.install_instance_name, '\repo')
            Add-Content -Path $TargetPath -Value "    home_path_src: $home_path_src" -Encoding 'utf8'
        }
        elseif ($line.StartsWith("    database:"))
        {
            Add-Content -Path $TargetPath -Value "    database: '$( $cfg.install_instance_name )'" -Encoding 'utf8'
        }
        elseif ($line.StartsWith("    DATABASE_ENGINE:"))
        {
            if (($cfg.db_engine -eq 'mssql') -or ($cfg.db_engine -eq 'postgres'))
            {
                Add-Content -Path $TargetPath -Value "    DATABASE_ENGINE: '$( $cfg.db_engine )'" -Encoding 'utf8'
            }
        }
        elseif ($line.StartsWith("    CONNECTION_STRING:"))
        {
            $db = $cfg.install_instance_name
            if ($IsAfterInstall)
            {
               $db =  '{{ database }}'
            }
            if ($cfg.db_engine -eq 'mssql')
            {
                $connection_string = "data source=$( $cfg.db_server );initial catalog=${db};user id=$( $cfg.db_user );Password=$( $cfg.db_password )"
            }
            elseif ($cfg.db_engine -eq 'postgres')
            {
                $connection_string = "server=$( $cfg.db_server );port=$( $cfg.postgres_port );database=$( db );user id=$( $cfg.db_user );Password=$( $cfg.db_password )"
            }
            else
            {
                Write-Error 'Wrong db_engine configuration'
            }
            Add-Content -Path $TargetPath -Value "    CONNECTION_STRING: '$connection_string'" -Encoding 'utf8'
        }
        elseif ($line.StartsWith("    QUEUE_CONNECTION_STRING:"))
        {
            $queue_exchange = $cfg.install_instance_name
            if ($IsAfterInstall)
            {
               $queue_exchange =  'RX_{{ database }}'
            }
            $queue_string = "virtualhost=$( $cfg.queue_virtual_host );hostname=$( $cfg.queue_server );port=5672;username=$( $cfg.queue_user );password=$( $cfg.queue_password );Exchange=$( $queue_exchange )"
            Add-Content -Path $TargetPath -Value "    QUEUE_CONNECTION_STRING: '$queue_string'" -Encoding 'utf8'
        }
        elseif ($line.StartsWith("    DATA_PROTECTION_CERTIFICATE_THUMBPRINT:"))
        {
            Add-Content -Path $TargetPath -Value "    DATA_PROTECTION_CERTIFICATE_THUMBPRINT: '$( $cfg.ssl_cert_thumbprint )'" -Encoding 'utf8'
        }
        elseif ($line.StartsWith("    MONGODB_CONNECTION_STRING:"))
        {
            Add-Content -Path $TargetPath -Value "    MONGODB_CONNECTION_STRING: 'mongodb://$( $cfg.mongo_user ):$( $cfg.mongo_password )@$( $mongo_server ):27017'" -Encoding 'utf8'
        }
        elseif ($line.StartsWith("    AUTHENTICATION_PASSWORD:"))
        {
            Add-Content -Path $TargetPath -Value "    AUTHENTICATION_PASSWORD: '$( $cfg.service_user_password )'" -Encoding 'utf8'
        }
        elseif ($line.StartsWith("        COMPANY_CODE:"))
        {
            Add-Content -Path $TargetPath -Value "        COMPANY_CODE: '$( $cfg.company_code )'" -Encoding 'utf8'
        }
        elseif ($line.StartsWith("    postgresql_bin:"))
        {
            Add-Content -Path $TargetPath -Value "    postgresql_bin: '$( $cfg.postgresql_bin )'" -Encoding 'utf8'
        }
        elseif ($line.StartsWith("    LOGS_PATH:"))
        {
            $root_logs_path = -join ($cfg.root_rx_path, '\', $cfg.logs_path_relative)
            Add-Content -Path $TargetPath -Value "    LOGS_PATH: '$root_logs_path\{{ instance_name }}'" -Encoding 'utf8'
        }
        else
        {
            Add-Content -Path $TargetPath -Value $line -Encoding 'utf8'
        }
    }
}


# Parse cfg
$cfg = Get-Content $cfg_path -Encoding 'utf8' | Out-String | ConvertFrom-Yaml
$root_path = $cfg.root_rx_path
$before_install_cfg_path = -join ($root_path, '\', $cfg.update_config_before_install_path_relative)
$after_install_cfg_path = -join ($root_path, '\', $cfg.update_config_after_install_path_relative)
$after_install_cfg_wcf_path = -join ($root_path, '\', $cfg.update_config_after_install_wcf_path_relative)
$root_logs_path = -join ($root_path, '\', $cfg.logs_path_relative)

# Create packages
Create-Folders-If-Not-Exist -TargetPath (-join ($root_path, '\', $cfg.instances_path_relative)) | Out-Null
Create-Folders-If-Not-Exist -TargetPath $root_logs_path | Out-Null

# Modify install-cfgs and copy to target
# TODO drop if error?
if (Test-Path -Path $before_install_cfg_path)
{
    Remove-Item $before_install_cfg_path -Force | Out-Null
}
Copy-Modified-Config -SourcePath ( -join ($util_root, '\', 'update_config_before_install.yml')) -TargetPath $before_install_cfg_path -IsAfterInstall $false | Out-Null

if (Test-Path -Path $after_install_cfg_path)
{
    Remove-Item $after_install_cfg_path -Force | Out-Null
}
Copy-Modified-Config -SourcePath ( -join ($util_root, '\', 'update_config_after_install.yml')) -TargetPath $after_install_cfg_path -IsAfterInstall $true | Out-Null

if (Test-Path -Path $after_install_cfg_wcf_path)
{
    Remove-Item $after_install_cfg_wcf_path -Force | Out-Null
}
Copy-Modified-Config -SourcePath ( -join ($util_root, '\', 'update_config_after_install_wcf.yml')) -TargetPath $after_install_cfg_wcf_path -IsAfterInstall $true | Out-Null
