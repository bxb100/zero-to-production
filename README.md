[![codecov](https://codecov.io/github/bxb100/zero-to-production/branch/main/graph/badge.svg?token=MAA8R3RY6O)](https://codecov.io/github/bxb100/zero-to-production)

[![Lockbud](https://github.com/bxb100/zero-to-production/actions/workflows/lockbud.yml/badge.svg?branch=main)](https://github.com/bxb100/zero-to-production/actions/workflows/lockbud.yml)

[![Rust](https://github.com/bxb100/zero-to-production/actions/workflows/general.yml/badge.svg)](https://github.com/bxb100/zero-to-production/actions/workflows/general.yml)

[![Security audit](https://github.com/bxb100/zero-to-production/actions/workflows/audit.yml/badge.svg)](https://github.com/bxb100/zero-to-production/actions/workflows/audit.yml)

## Environment

* Rust stable
* sqlx
* psql
* docker
> online
* Terraform
* fly CLI
* GNU make

## Infrastructure
[//]: # (https://mermaid.js.org/syntax/stateDiagram.html)
```mermaid
stateDiagram-v2
    [*] --> Terraform
    state Terraform {
        neon: Neon provider
        fly: Fly provider
        [*] --> neon
        note right of neon
            build neon project, role and database
        end note
        neon --> fly
        note left of fly
            build fly app, and set neon host,name,password to the fly app secrets
        end note
        fly --> [*]
    }
    flyCLI: fly deploy
    note right of flyCLI: Build dockerfile deploy to the fly app.
    Terraform --> flyCLI
```

* https://fly.io host online test project
* https://neon.tech host online test database
* https://app.terraform.io host terraform state, execute in the local
* [terraform-community-providers/neon](https://registry.terraform.io/providers/terraform-community-providers/neon/latest) terraform neon provider
* [floydspace/fly]( https://registry.terraform.io/providers/floydspace/fly/latest) terraform fly provider[^not official]

[^not official]: https://github.com/fly-apps/terraform-provider-fly/pull/106#issuecomment-1501199345