
$util_root = -join ($PSScriptRoot, '\..\..\..')

# РџСѓС‚СЊ Рє С„Р°Р№Р»Сѓ СЃРµСЂС‚РёС„РёРєР°С‚Р°
$certPath = -join ($util_root, '\certs\localhost.pfx')
# РџР°СЂРѕР»СЊ РґР»СЏ СЃРµСЂС‚РёС„РёРєР°С‚Р°
$certPassword = "11111"

# РЈСЃС‚Р°РЅРѕРІРєР° СЃРµСЂС‚РёС„РёРєР°С‚Р° РІ С…СЂР°РЅРёР»РёС‰Рµ РєРѕРјРїСЊСЋС‚РµСЂР°
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import($certPath, $certPassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet)
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My", "LocalMachine")
$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
$store.Add($cert)
$store.Close()

# РџСѓС‚СЊ Рє С„Р°Р№Р»Сѓ РґРѕРІРµСЂРµРЅРЅРѕРіРѕ СЃРµСЂС‚РёС„РёРєР°С‚Р°
$trustedCertPath = -join ($util_root, '\certs\cacert.crt')

# РЈСЃС‚Р°РЅРѕРІРєР° РґРѕРІРµСЂРµРЅРЅРѕРіРѕ СЃРµСЂС‚РёС„РёРєР°С‚Р° РІ РґРѕРІРµСЂРµРЅРЅС‹Рµ С†РµРЅС‚СЂС‹ СЃРµСЂС‚РёС„РёРєР°С†РёРё
$trustedCert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$trustedCert.Import($trustedCertPath)
$trustedStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
$trustedStore.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
$trustedStore.Add($trustedCert)
$trustedStore.Close()
