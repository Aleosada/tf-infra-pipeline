# Instruções

## Pré requisitos

* Instalação do cli do github
* Criação de um access token para utilização do cli
* Autenticar no github cli com o comando `gh auth login`
* Instalação do terraform cli
* Instalação do AWS cli
* Configuração do AWS cli com o comando `aws configure`

## Criação do repositório no github

`gh repo create [name]`

## TODOS

[] Criar terraform para storage do arquivo de state do terraform no S3 e tabela dynamodb para lock do state
[] Criar terraform para criação da esteira de implantação
[] Criar script para automatizar a criação do repositório no github
