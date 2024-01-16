<p align="center">
  <img src="https://raw.githubusercontent.com/cert-manager/cert-manager/d53c0b9270f8cd90d908460d69502694e1838f5f/logo/logo-small.png" height="256" width="256" alt="cert-manager project logo" />
</p>

# ACME webhook for my homelab (namecheap at the moment)

The ACME issuer type supports an optional 'webhook' solver, which can be used
to implement custom DNS01 challenge solving logic.

This is useful if you need to use cert-manager with a DNS provider that is not
officially supported in cert-manager core.

## Why not in core?

As the project & adoption has grown, there has been an influx of DNS provider
pull requests to our core codebase. As this number has grown, the test matrix
has become un-maintainable and so, it's not possible for us to certify that
providers work to a sufficient level.

By creating this 'interface' between cert-manager and DNS providers, we allow
users to quickly iterate and test out new integrations, and then packaging
those up themselves as 'extensions' to cert-manager.

We can also then provide a standardised 'testing framework', or set of
conformance tests, which allow us to validate the a DNS provider works as
expected.

## Creating your own webhook

Webhook's themselves are deployed as Kubernetes API services, in order to allow
administrators to restrict access to webhooks with Kubernetes RBAC.

This is important, as otherwise it'd be possible for anyone with access to your
webhook to complete ACME challenge validations and obtain certificates.

To make the set up of these webhook's easier, we provide a template repository
that can be used to get started quickly.

## Instructions for use with Let's Encrypt

Use helm to deploy this into your `cert-manager` namespace:

``` sh
# Make sure you're in the right context:
# kubectl config use-context mycontext

# cert-manager is by default in the cert-manager context
helm install -n cert-manager homelab-webhook deploy/homelab-cert-manager-webhook/
```

Create the cluster issuers:

``` sh
helm install --set email=yourname@example.com -n cert-manager homelab-issuers deploy/homelab-letsencrypt-issuers/
```

Go to namecheap and set up your API key (note that you'll need to whitelist the
public IP of the k8s cluster to use the webhook), and set the secret:

``` yaml
apiVersion: v1
kind: Secret
metadata:
  name: namecheap-credentials
  namespace: cert-manager
type: Opaque
stringData:
  apiKey: my_api_key_from_namecheap
  apiUser: my_username_from_namecheap
```

Now you can create a certificate in staging for testing:

``` yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-cert-staging
  namespace: default
spec:
  secretName: wildcard-cert-staging
  commonName: "*.<domain>"
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-staging
  dnsNames:
  - "*.<domain>"
```

And now validate that it worked:

``` sh
kubectl get certificates -n default
kubectl describe certificate wildcard-cert-staging
```

And finally, create your production cert, and it'll be ready to use in the
`wildcard-cert-prod` secret.

``` yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-cert-prod
  namespace: default
spec:
  secretName: wildcard-cert-prod
  commonName: "*.<domain>"
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-prod
  dnsNames:
  - "*.<domain>"
```
