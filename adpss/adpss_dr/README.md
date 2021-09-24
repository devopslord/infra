Provisioning instances in US-West-1 


Inputs:
* Source Region AMI Id
* Source Region EBS Snapshot Ids
* VPN SecurityGroup Id

Steps:
1. Run adpss_dr vpc terraform script (wait till provisioned)
2. Run ec2/adpss_dr terraform script (provision adpss ec2)
3. Run adpss_dr vpn terraform script (provision adpss vpn)
4. In adpss_vpn_client project (bitbucket)
4a. download the vpn client configuration file
4b. create/update the files of each user with vpn endpoint

Time to complete 
- 30 min to provision baseline infrastructure
- 30/60min to copy TB size snapshots and restore volumes
- Need to spot validate ACLs on each drive (30min)
- License apply ot each software (SAS, SPSS, MS Office) varies


