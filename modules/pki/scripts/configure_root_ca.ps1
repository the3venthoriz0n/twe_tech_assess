$crllist = Get-CACrlDistributionPoint; foreach ($crl in $crllist) {Remove-CACrlDistributionPoint $crl.uri -Force}; Add-CACRLDistributionPoint -Uri C:\Windows\System32\CertSrv\CertEnroll%3%8.crl -PublishToServer -Force Add-CACRLDistributionPoint -Uri https://www.contoso.com/pki/%3%8.crl -AddToCertificateCDP -Force $aialist = Get-CAAuthorityInformationAccess; foreach ($aia in $aialist) {Remove-CAAuthorityInformationAccess $aia.uri -Force}; Certutil -setreg CA\CRLOverlapPeriodUnits 12 Certutil -setreg CA\CRLOverlapPeriod "Hours" Certutil -setreg CA\ValidityPeriodUnits 10 Certutil -setreg CA\ValidityPeriod "Years" restart-service certsvc certutil -crl