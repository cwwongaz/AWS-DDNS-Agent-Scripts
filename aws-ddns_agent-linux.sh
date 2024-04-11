#!/bin/bash
#Variable Declaration - Change These
AWS_HOSTED_ZONE_ID="<YOUR_HOSTED_ZONE_ID_HERE>"
AWS_DNSNAME="<YOUT_AWS_DNSNAME_HERE>"
AWS_DNSRECORDTYPE="A"
TTL=600
JSON_PAYLOAD_FILE_NAME="payload.json"
JSON_PAYLOAD_FILE_PATH="$(pwd)/$JSON_PAYLOAD_FILE_NAME"

#get current IP address
CURRENT_IP=$(curl http://checkip.amazonaws.com/)

#validate IP address (makes sure Route 53 doesn't get updated with a malformed payload)
if [[ ! "$CURRENT_IP" =~ ^[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}$ ]]; then
    exit 1
fi

#get current
AWS_DOMAIN_RECORD_IP=$(aws route53 list-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID | 
  jq -r '.ResourceRecordSets[] | select (.Name == "'"$AWS_DNSNAME"'") | 
  select (.Type == "'"$AWS_DNSRECORDTYPE"'") | .ResourceRecords[0].Value'
)

#check if IP is different from Route 53
if [[ "$CURRENT_IP" == "$AWS_DOMAIN_RECORD_IP" ]]; then
    echo "No Change in IP, Exiting!"
    exit 1
fi

echo "IP Changed, Updating Records"

#prepare route 53 payload
cat > $JSON_PAYLOAD_FILE_PATH << EOF
    {
      "Comment":"Updated From DDNS Shell Script",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value":"$CURRENT_IP"
              }
            ],
            "Name":"$AWS_DNSNAME",
            "Type":"$AWS_DNSRECORDTYPE",
            "TTL":$TTL
          }
        }
      ]
    }
EOF

#update records
aws route53 change-resource-record-sets --hosted-zone-id $AWS_HOSTED_ZONE_ID --change-batch "file://$JSON_PAYLOAD_FILE_PATH"
