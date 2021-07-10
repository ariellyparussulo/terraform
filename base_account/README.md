# Base Account Project (Projeto de Conta de Base)
## Introdução
Esse projeto propõe uma estrutura padrão de criação de uma conta nova AWS usando Terraform.

## Antes de começar
1. instale o [terraform](https://www.terraform.io/downloads.html) em sua máquina.
2. Em sua conta AWS, crie um S3 Bucket para salvar o estado (tfstate) de sua infraestrutura.
3. esse **bucket** deverá ser alterado no arquivo [main](./main.tf) deste projeto da seguinte forma:

```tf
provider "aws" {
  region = "<< sua região >>"
}

terraform {
  backend "s3" {
    bucket = "<< seu bucket S3 >>
    key    = "<< nome do prefixo S3 que você deseja utilizar para esse projeto >>
    region = "<< sua região >>"
  }
}
```

Sendo:
* **region:** sua região na sua conta da AWS. Padrão: **us-east-1**.
* **bucket:** o bucket que você criou no passo **2**.
* **key:** Prefixo do seu Bucket S3. Padrão: **base-account**.

## Como rodar:
1. Dentro dessa pasta (**base_account**) rode `terraform init`.
2. Depois rode `terraform apply` e verifique as diferenças de sua aplicação.
3. O **diff** do terraform deve mostrar a criação dos seguintes recursos:

* um grupo IAM chamada **operations**.
* a configuração do Cloud Trail em sua conta.
* a configuração do AWS Config em sua conta.
* a criação de uma VPC em sua conta.
* duas instâncias EC2 para rodar um nginx e um banco de dados postgres.

## Personalizando esse projeto
Nessa sessão listarei os módulos desse projeto e o que atualmente pode ser personalizado atualmente neste.

### Módulo operations_group
|variável|descrição|valor padrão|
|-|-|-|
|name|nome do seu grupo IAM|operations|
|attach_iam_self_management_policy|permite os membros deste grupo de gerenciar suas credenciais e MFA|true|
|custom_group_policy_arns|lista de políticas IAM associadas à esse grupo|

Para mais informações, acesse [a documentação desse módulo](https://github.com/terraform-aws-modules/terraform-aws-iam/blob/master/modules/iam-group-with-policies/README.md).

### Módulo cloud_trail_monitoring
|variável|descrição|valor padrão|
|-|-|-|
|bucket|nome do seu bucket para salvar os dados do cloud trail.|-|
|bucket_prefix|o prefixo onde você salvará os dados do cloud trail.|cloudtrail|

### Módulo account_config
|variável|descrição|valor padrão|
|-|-|-|
|bucket|nome do bucket para salvar os dados do seu AWS Config.|-|
|bucket_prefix|Nome do prefixo onde o AWS Config salvará seus dados.|config-logs|
|required_tags|Possui as tags necessárias para os recursos dessa conta. Você pode utilizar os parâmetros listados na [documentação da AWS](https://docs.aws.amazon.com/config/latest/developerguide/required-tags.html)|{ tag1Key = "Name" }|
|iam_password_policy|define a política de senhas de sua conta. Você pode utilizar os parâmetros listados na [documentação da AWS](https://docs.aws.amazon.com/config/latest/developerguide/iam-password-policy.html)|{ MinimumPasswordLength = "64" PasswordReusePrevention = "3" MaxPasswordAge = "30" }|
|allowed_amis|Lista de amis permitidas nessa conta. Você pode utilizar os parâmetros listados na [documentação da AWS](https://docs.aws.amazon.com/config/latest/developerguide/approved-amis-by-id.html)|ami-0ab4d1e9cf9a1215a,ami-09e67e426f25ce0d7|

Como esse módulo é personalizado, você pode adicionar novas regras em sua conta. Todas elas são listadas na [documentação da AWS](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html). A regra pode ser adicionada no arquivo [./modules/config/main.tf](./modules/config/main.tf) da seguinte maneira:

```tf
resource "aws_config_config_rule" "<<sua-politica>>" {
  name        = "<<sua-politica>>"

  source {
    owner             = "AWS"
    source_identifier = "<<identificador_da_regra>>"
  }

  input_parameters = jsonencode(var.seu_parametro)
  depends_on = [aws_config_delivery_channel.config]
}
```
## Módulo vpc
|variável|descrição|valor padrão|
|-|-|-|
|name|nome da sua VPC|giropops|
|cidr|O CIDR de sua VPC|10.0.0.0/16|
|azs|Zonas de disponibilidade da sua VPC.|us-east-1a|
|private_subnets|Suas subredes privadas|["10.0.1.0/24"]|
|public_subnets|Suas subnets públicas|["10.0.101.0/24"]|
|enable_nat_gateway|Opção de uso da NAT Gateway|true|
|enable_vpn_gateway|Opção de uso do seu Internet Gateway|true|

Você pode personalizar mais sua VPC usando a [documentação desse módulo](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest).

## Módulo web_server
Cria uma instância na subrede pública de sua conta. Você pode personalizar esse módulo da maneira que quiser a fim de criar a instância que você precisa.

## Módulo database
Mesma coisa do módulo anterior mas essa instância se encontra em uma rede privada. Aqui você pode criar instâncias que você não deseja expor para a internet.