
The VPC Flowlog for ADPSS VPC uses the below custom format for capturing the TCP traffic.

```
version vpc-id subnet-id instance-id interface-id account-id type srcaddr dstaddr srcport dstport pkt-srcaddr pkt-dstaddr protocol bytes packets start end action tcp-flags az-id log-status
```

For CW Insights
* Use @messages field