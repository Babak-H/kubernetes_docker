# Spring Boot Microservice Helm Chart

This folder is now a Helm chart for the `mddz` Spring Boot microservice cluster.

## Render

```sh
helm template springboot-microservice . --namespace mddz
```

## Install Or Upgrade

```sh
helm upgrade --install springboot-microservice . --namespace mddz --create-namespace
```

If you use Helmfile:

```sh
helmfile -f helmfile.yaml apply
```

## Required External Secrets

By default, this chart expects these Secrets to already exist:

- `my-reg-key`
- `eureka-pass-secret`
- `encrypt-key-secret`
- `my-ssh-key`
- `tls-secret`

Set `secrets.create=true` in `values.yaml` only if you want Helm to create the application Secrets from local values.
