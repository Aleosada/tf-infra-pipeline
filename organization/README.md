# AWS Organization - Criação de OUs e contas

## Pré requisitos

* Configuração do AWS cli para conta master
* Criação dos emails necessários para as contas
* Ter criado um bucket para salvar os arquivos de estado do terraform
* Ter criado a tabela no dynamodb para guardar informção de lock do estado do terraform

## Intruções

* Criar manualmente a organização, via console AWS, a partir da conta master (não root)
* Alterar as informações do bucket e dynamo table no arquivo main.tf
* Alterar as variáveis no arquivo terraform.tfvars
* Executar os comandos:
`terraform init
terraform plan
terraform apply
`
