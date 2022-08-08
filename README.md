## Addressing IPv4 address Exhaustion in Amazon EKS Clusters using private NAT gateways

This directory contains software artifacts for implementing the networking architecture discussed in this blog in conjunction with an Amazon EKS cluster. It demonstrates a use case where workloads deployed in an EKS cluster provisioned in a VPC are made to communicate, using a private NAT gateway, with workloads deployed to another EKS cluster in a different VPC with overlapping CIDR ranges. 

<img class="wp-image-1960 size-full" src="../images/network-architecture.png" alt="Network architecture"/>
<img class="wp-image-1960 size-full" src="../images/solution-architecture.png" alt="Solution architecture"/>

