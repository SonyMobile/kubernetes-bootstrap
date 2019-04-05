# ExternalDNS

[ExternalDNS](https://github.com/kubernetes-incubator/external-dns) synchronizes exposed Kubernetes
Services and Ingresses with DNS providers (Route53 in our installation).

DNS records will be automatically created in multiple situations:

1. Setting `spec.rules.host` on an ingress object.
2. Setting `spec.tls.hosts` on an ingress object.
3. Adding the annotation `external-dns.alpha.kubernetes.io/hostname` on an ingress object.
4. Adding the annotation `external-dns.alpha.kubernetes.io/hostname` on a `type=LoadBalancer`
   service object.

## Install

```
$ make deploy-helm
$ make deploy-nginx-ingress
$ make deploy-external-dns
$ make deploy-app-echoserver
```

After roughly two minutes check that a corresponding DNS record for the echoserver will be created.

```
$ CLUSTER_FQDN=lab.example.com
$ HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
    --query "HostedZones[?Name=='$CLUSTER_FQDN.'].Id" --output text)
$ aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" \
    --query "ResourceRecordSets[?Name == 'echoserver.$CLUSTER_FQDN.']|[?Type == 'A']"

[
    {
        "Name": "echoserver.lab.example.com.",
        "Type": "A",
        "AliasTarget": {
            "HostedZoneId": "Z32O12XQLNTSW2",
            "DNSName": "aa7977edbee6511e88b150ad0f74529d-1808636017.eu-west-1.elb.amazonaws.com.",
            "EvaluateTargetHealth": true
        }
    }
]
```

You can also heck the logs from of external-dns pod to see that DNS records are created as
expected for your services.

```
$ kubectl logs -f lab-external-dns-external-dns-6886d7f6b7-tsrtc
time="2018-11-23T08:38:35Z" level=info msg="config: {Master: KubeConfig: RequestTimeout:30s IstioIngressGateway:istio-system/istio-ingressgateway Sources:[service ingress] Namespace: AnnotationFilter: FQDNTemplate: CombineFQDNAndAnnotation:false Compatibility: PublishInternal:false PublishHostIP:false ConnectorSourceServer:localhost:8080 Provider:aws GoogleProject: DomainFilter:[lab.example.com] ZoneIDFilter:[] AlibabaCloudConfigFile:/etc/kubernetes/alibaba-cloud.json AlibabaCloudZoneType: AWSZoneType:public AWSAssumeRole: AWSBatchChangeSize:4000 AWSBatchChangeInterval:1s AWSEvaluateTargetHealth:true AzureConfigFile:/etc/kubernetes/azure.json AzureResourceGroup: CloudflareProxied:false InfobloxGridHost: InfobloxWapiPort:443 InfobloxWapiUsername:admin InfobloxWapiPassword: InfobloxWapiVersion:2.3.1 InfobloxSSLVerify:true DynCustomerName: DynUsername: DynPassword: DynMinTTLSeconds:0 OCIConfigFile:/etc/kubernetes/oci.yaml InMemoryZones:[] PDNSServer:http://localhost:8081 PDNSAPIKey: PDNSTLSEnabled:false TLSCA: TLSClientCert: TLSClientCertKey: Policy:upsert-only Registry:txt TXTOwnerID:default/lab-external-dns-external-dns TXTPrefix: Interval:1m0s Once:false DryRun:false LogFormat:text MetricsAddress::7979 LogLevel:info TXTCacheInterval:0s ExoscaleEndpoint:https://api.exoscale.ch/dns ExoscaleAPIKey: ExoscaleAPISecret: CRDSourceAPIVersion:externaldns.k8s.io/v1alpha CRDSourceKind:DNSEndpoint ServiceTypeFilter:[]}"
time="2018-11-23T08:38:35Z" level=info msg="Created Kubernetes client https://100.64.0.1:443"
time="2018-11-23T08:38:36Z" level=info msg="All records are already up to date"
time="2018-11-23T08:39:35Z" level=info msg="All records are already up to date"
time="2018-11-23T08:40:35Z" level=info msg="Desired change: CREATE echoserver.lab.example.com A"
time="2018-11-23T08:40:35Z" level=info msg="Desired change: CREATE echoserver.lab.example.com TXT"
time="2018-11-23T08:40:36Z" level=info msg="2 record(s) in zone lab.example.com. were successfully updated"
time="2018-11-23T08:41:35Z" level=info msg="All records are already up to date"
```
