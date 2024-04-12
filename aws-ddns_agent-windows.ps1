<#
    .Description
    This helper Script detect the Dynamic IP changes (For those without a fixed IP Address who are in demand to use DNS) and update the AWS route 53 DNS record with the changed IP.
#>

$AWS_HOSTED_ZONE_ID="<YOUR_HOSTED_ZONE_ID_HERE>"
$AWS_DNSNAME="<YOUR_DNSNAME_HERE>"
$AWS_DNSRECORDTYPE="A"
$TTL=3600
$JSON_PAYLOAD_FILE_NAME="payload.json"
$JSON_PAYLOAD_FILE_PATH=Join-Path -Path "$PWD" -ChildPath "$JSON_PAYLOAD_FILE_NAME"

# get current IP address
$CURRENT_IP=$(Invoke-WebRequest -Uri 'http://checkip.amazonaws.com/').Content.Trim()

#validate IP address (makes sure Route 53 doesn't get updated with a malformed payload)
if ( $CURRENT_IP -notmatch '^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$' ) {
    exit
}

# get current DNS A Record
$AWS_DOMAIN_INFO = aws route53 list-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID `
                   | ConvertFrom-Json

$AWS_DOMAIN_RECORD_IP = $AWS_DOMAIN_INFO.ResourceRecordSets `
                        | where { $_.Name -eq $AWS_DNSNAME }

if ( $AWS_DOMAIN_RECORD_IP.ResourceRecords.Value -match $CURRENT_IP ) {
    echo "No Change in IP, Exiting!"
    exit
}

echo "IP Changed, Updating Records"

$PayLoad = @{
    Comment = "Updated From DDNS Shell Script"
    Changes = @(
        @{
            Action="UPSERT"
            ResourceRecordSet = @{
                ResourceRecords = @(
                    @{
                        Value = "$CURRENT_IP"
                    }
                )
                Name="$AWS_DNSNAME"
                Type="$AWS_DNSRECORDTYPE"
                TTL=$TTL
            }
        }
    )
} | ConvertTo-Json -depth 5 | Out-File -FilePath $JSON_PAYLOAD_FILE_PATH -Force -Encoding ASCII

echo "file://$JSON_PAYLOAD_FILE_PATH"

# update DNS records
aws route53 change-resource-record-sets --hosted-zone-id "$AWS_HOSTED_ZONE_ID" --change-batch "file://$JSON_PAYLOAD_FILE_PATH"
