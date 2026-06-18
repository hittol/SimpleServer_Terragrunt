# SimpleArchi Terragrunt

### 구조

```
.
├── root.hcl
├── source/
│   ├── acr/
│   ├── aks/
│   ├── mysql/
│   ├── natgw/
│   ├── peering/
│   ├── privatedns/
│   ├── rg/
│   ├── sa/
│   ├── vm/
│   ├── vnet/
│   └── vpngw/
│       ├── main.tf
│       ├── variables.tf
│       └── output.tf
└── live/
    ├── hub/
    │   ├── env.hcl
    │   ├── natgw/
    │   ├── rg/
    │   ├── vm/
    │   ├── vnet/
    │   └── vpngw/
    │       └── terragrunt.hcl
    └── spoke/
        ├── env.hcl
        ├── acr/
        ├── aks/
        ├── mysql/
        ├── peering/
        ├── privatedns/
        ├── rg/
        └── vnet/
            └── terragrunt.hcl
```


전체 순차 실행은 각 live 의 루트에서 가능합니다.

```bash
terragrunt run-all plan
terragrunt run-all apply
```


### Backend 교체

Azure Storage backend로 바꾸려면 `root.hcl`의 `remote_state`에서 `config` 내용을 변경합니다.
