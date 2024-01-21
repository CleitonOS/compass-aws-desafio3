<p align="center">
  <a href="" rel="noopener">
 <img max-width=400px height=100px src="https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Logo_CompassoUOL_Positivo.png/1200px-Logo_CompassoUOL_Positivo.png" alt="Project logo"></a>
</p>

<h1 align="center">Criar um terraform para deploy do API Gateway e uma função Lambda</h1> 
<p align="center"><i></i></p>

## 📑 Requisitos

- Ter AWS CLI instalado e configurado.

- Ter terraform instalado.

Para mais informações, há um repositório com as informações necessárias para instalar e configurar o terraform e o AWS CLI: [Instalando e configurando Terraform](https://github.com/CleitonOS/compass-terraform-desafio1)

## 📝 Tabela de conteúdos
- [Criando arquivo YAML do Deploy da Lambda Function no Editor de Textos (Passo 1)](#step1)
- [Criando a pilha/stack no Cloudformation (Passo 2)](#step2)
- [Configurando API Gateway (Passo 3)](#step3)
- [Referências](#documentation)

## ⚙️ Construindo o pacote de funções Lambda (Passo 1)<a name = "step1"></a>

- Executaremos essas etapas de construção manualmente e construiremos uma função AWS Lambda muito simples.

1. Começamos criando um novo diretório chamado **pkg-lambda-function**

- Usaremos o JavaScript para o tempo de execução, portanto nosso arquivo vai se chamar **"main.js"**, com o seguinte código-fonte:

    ```yaml
    'use strict';

    exports.handler = function (event, context, callback) {
        var response = {
            statusCode: 200,
            headers: {
                'Content-Type': 'text/html; charset=utf-8',
            },
            body: "<p>Hello world!</p>",
        };
        callback(null, response);
    };
    ```

    - O código acima é a função mais simples possível para uso com o API Gateway, onde retornamos "Hello world!".

2. Agora vamos compactar esse arquivo/pasta:
    
## ⚙️ Criando a pilha/stack no Cloudformation (Passo 2)<a name = "step2"></a>

1. Acesse o console da AWS, pesquise por Cloudformation e crie uma pilha.
    - Selecione "O modelo está pronto" e "Fazer upload de um arquivo de modelo".
    - Faça o upload do arquivo YAML que você criou.

    <img src="./Screenshots/stack-creation.png" width="80%">

    <br>

2. Dê um nome a pilha:

    <img src="./Screenshots/stack-name.png" width="80%">

    <br>

3. Pule a etapa 3 e siga para a etapa 4

    - Na etapa 4, confirme a caixa de seleção antes de prosseguir com envio da pipeline.

    <img src="./Screenshots/accept-stack.png" width="80%">
    
    <br>

4. Agora se tudo ocorrer bem, serão criados os recursos especificados na pipeline.

    - Espere alguns minutos até que sejam criados os recursos.

    <img src="./Screenshots/resources-creation.png" width="80%">
    
- Recursos criados:

    <img src="./Screenshots/resources.png" width="80%">

    - Caso queira testar o código lambda, clique no ID físico da Lambda Function e faça o teste
    - Talvez você encontre alguns erros ao executar o código lambda, esse código utilizado é apenas um exemplo, fique á vontade para fazer quaisquer alterações no código.

## ⚙️ Configurando API Gateway (Passo 3)<a name = "step3"></a>

- Antes de começarmos, é preciso entender que todas as solicitações recebidas pelo API Gateway devem corresponder a um recurso e método configurados para serem tratados.
- Com isso, vamos anexar o seguinte código ao arquivo **lambda.tf** para definir um recurso de proxy:

    ```yaml
    resource "aws_api_gateway_resource" "proxy" {
      rest_api_id = "${aws_api_gateway_rest_api.example.id}"
      parent_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"
      path_part   = "{proxy+}"
    }

    resource "aws_api_gateway_method" "proxy" {
      rest_api_id   = "${aws_api_gateway_rest_api.example.id}"
      resource_id   = "${aws_api_gateway_resource.proxy.id}"
      http_method   = "ANY"
      authorization = "NONE"
    }
    ```

1. Crie um novo arquivo **api_gateway.tf** no mesmo diretório do **lambda.tf**.

- Vamos começar configurando o objetvo raiz "REST API", da seguinte forma:

    ```yaml
    resource "aws_api_gateway_rest_api" "example" {
      name        = "ServerlessExample"
      description = "Terraform Serverless Application Example"
    }
    ```

    - Essa "API Rest" é o contêiner para todos os outros objetos do API Gateway que criaremos, isso quer dizer que o que for criado estará dentro desse escopo.

2. Configurando para que as soliticações desse método sejam enviadas para a função Lambda definida anteriormente:

    ```yaml
    resource "aws_api_gateway_integration" "lambda" {
      rest_api_id = "${aws_api_gateway_rest_api.example.id}"
      resource_id = "${aws_api_gateway_method.proxy.resource_id}"
      http_method = "${aws_api_gateway_method.proxy.http_method}"

      integration_http_method = "POST"
      type                    = "AWS_PROXY"
      uri                     = "${aws_lambda_function.example.invoke_arn}"
    }
    ```

- O **AWS_PROXY** tipo de integração faz com que o gateway de API chame a API de outro serviço da AWS. Neste caso, ele chamará a API do AWS Lambda para criar uma “invocação” da função Lambda.
- Infelizmente, o recurso proxy não pode corresponder a um caminho vazio na raiz da API. Para lidar com isso, uma configuração semelhante deve ser aplicada ao recurso raiz integrado ao objeto REST API:

    ```yaml
    resource "aws_api_gateway_method" "proxy_root" {
     rest_api_id   = "${aws_api_gateway_rest_api.example.id}"
     resource_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"
     http_method   = "ANY"
     authorization = "NONE"
    }

    esource "aws_api_gateway_integration" "lambda_root" {
     rest_api_id = "${aws_api_gateway_rest_api.example.id}"
     resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
     http_method = "${aws_api_gateway_method.proxy_root.http_method}"

     integration_http_method = "POST"
     type                    = "AWS_PROXY"
     uri                     = "${aws_lambda_function.example.invoke_arn}"
    }
    ```

3. Criando uma "implantação" do API Gateway para ativar a configuração e expor a API em uma URL que pode ser usada para testes:

    ```yaml
    resource "aws_api_gateway_deployment" "example" {
      depends_on = [
        "aws_api_gateway_integration.lambda",
        "aws_api_gateway_integration.lambda_root",
      ]

      rest_api_id = "${aws_api_gateway_rest_api.example.id}"
      stage_name  = "test"
    }
    ```

- Agora na linha de comando execute **terraform apply**, para criar estes objetos. (Certifique-se de estar na pasta dos arquivos criados do terraform)

    <img src="./Screenshots/result-terraform01.png" width="80%">

    - Recursos criados com sucesso.

4. Para finalizar precisamos permitir que o API Gateway acesse o Lambda.

- Por padrão, quaisquer dos dois serviços da AWS não têm acesso um ao outro, até que o acesso seja explicitamente concedido. Para funções Lambda, o acesso é concedido por meio do recurso **aws_lambda_permission**, que deve ser adicionado ao **lambda.tf** arquivo criado em etapa anterior:

- Vamos adicionar ao **lambda.tf**, este código:

    ```yaml
    resource "aws_lambda_permission" "apigw" {
      statement_id  = "AllowAPIGatewayInvoke"
      action        = "lambda:InvokeFunction"
      function_name = "${aws_lambda_function.example.function_name}"
      principal     = "apigateway.amazonaws.com"

      # The /*/* portion grants access from any method on any resource
      # within the API Gateway "REST API".
      source_arn = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
    }
    ```

- Para testar a API criada você precisará acessar sua URL de teste. 
- Para facilitar o acesso, adicione a seguinte saída no **lambda.tf**:

    ```yaml
    output "base_url" {
      value = "${aws_api_gateway_deployment.example.invoke_url}"
    }
    ```

- Aplique as alterações na linha de comando com **terraform apply**

- Esse deve ser o resultado:

    <img src="./Screenshots/result-terraform02.png" width="80%">

<br>

- Por fim, acesse a URL que foi retornada pela linha de comando e você verá uma mensagem sendo retornada do código de função do Lambda carregado anteriormente, por meio do endpoint do API Gateway.

    <img src="./Screenshots/api-response.png" width="80%">

### Desafio concluído!

## Referências utilizadas:<a name="documentation"></a>

- [Serverless Applications with AWS Lambda and API Gateway](https://registry.terraform.io/providers/hashicorp/aws/2.34.0/docs/guides/serverless-with-aws-lambda-and-api-gateway)

