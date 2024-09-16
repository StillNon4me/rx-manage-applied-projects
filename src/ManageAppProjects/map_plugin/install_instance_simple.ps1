Param ([string] $rx_instaler_dir_path, #РєР°С‚Р°Р»РѕРі СЃ РґРёСЃС‚СЂРёР±СѓС‚РёРІРѕРј СѓСЃС‚Р°РЅР°РІР»РёРІР°РµРјРѕРіРѕ Р±РёР»РґР°
    [string] $instance_name, #РёРјСЏ РёРЅСЃС‚Р°РЅСЃР°
    [int] $port                        #port
)

# Check config path
$util_root = -join ($PSScriptRoot, '\..\..\..')
$cfg_path = -join ($util_root, '\settings.yml')
if (!(Test-Path $cfg_path))
{
    Write-Error (-join ('Config not found, path: ', $cfg_path))
    return
}

$cfg = Get-Content $cfg_path -Encoding 'utf8' | Out-String | ConvertFrom-Yaml
$root_path = $cfg.root_rx_path
$instance_root_dir_path = (-join ($root_path, '\', $cfg.instances_path_relative))
$map_plugin_path = $PSScriptRoot
$cfg_before_install_path = -join ($root_path, '\', $cfg.update_config_before_install_path_relative)
$cfg_after_install_path = -join ($root_path, '\', $cfg.update_config_after_install_path_relative)
$cfg_after_install_wfc_path = -join ($root_path, '\', $cfg.update_config_after_install_wcf_path_relative)

$params = @{
    rx_instaler_dir_path = $rx_instaler_dir_path
    instance_name = $instance_name
    port = $port
    instance_root_dir_path = $instance_root_dir_path
    map_plugin_path = $map_plugin_path
    cfg_before_install_path = $cfg_before_install_path
    cfg_after_install_path = $cfg_after_install_path
    cfg_after_install_wfc_path = $cfg_after_install_wfc_path
}

& "$PSScriptRoot/install_instance.ps1" @params

# HACK remove fake-comments
$original_cfg_path = "$instance_root_dir_path\$instance_name\etc\config.yml"
$original_cfg = Get-Content -Path $original_cfg_path -Encoding 'utf8'
$tmp_cfg_path = "$original_cfg_path.tmp.yml"
foreach ($line in $original_cfg)
{
    if ($line.Contains("#:auto_remove_comment:"))
    {
        $modified_line = $line -replace "#:auto_remove_comment:"
        Add-Content -Path $tmp_cfg_path -Value $modified_line -Encoding 'utf8'
    }
    else
    {
        Add-Content -Path $tmp_cfg_path -Value $line -Encoding 'utf8'
    }
}

Copy-Item -Path $tmp_cfg_path -Destination $original_cfg_path -Force
Remove-Item -Path $tmp_cfg_path
