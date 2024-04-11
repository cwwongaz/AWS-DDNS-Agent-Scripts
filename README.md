# AWS-DDNS-Agent-Scripts
This helper Script detect the Dynamic IP changes (For those without a fixed IP Address who are in demand to use DNS) and update the AWS route 53 DNS record with the changed IP.

Remark: The powershell script referenced the script for aws DDNS script for linux in this article, the linux version of the script is added with some adjustments. https://www.chenyun.org/2023/06/20/DDNS%20for%20AWS%20Route%2053/ 

Prerequisite: 
  - Linux:
      - aws cli installed
      - sudo apt install jq
  - Windows:
      - aws cli installed

Usage 
- Linux:
      - aws-ddns_agent-linux.sh
  - Windows:
      - aws-ddns_agent-windows.ps1

Reference: https://www.chenyun.org/2023/06/20/DDNS%20for%20AWS%20Route%2053/
