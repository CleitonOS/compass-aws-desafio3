// "API Rest" é o container para todos os outros objetos do API Gateway que iremos criar.

resource "aws_api_gateway_rest_api" "example" {
  name        = "ServerlessExample"
  description = "Terraform Serverless Application Example"
}

// Cada método em um recurso de API Gateway tem uma integração no qual especifica onde as solicitações recebidas são roteadas.

// Configurando as solicitações para o método proxy configurado anteriormente no 'lambda.tf'

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.example.invoke_arn}"
}

// O recurso proxy não pode corresponder a um caminho vazio na raiz da API;
// Para lidar com isso, uma configuração semelhante deve ser aplicada ao recurso raiz integrado ao objeto da API REST.

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.example.id}"
  resource_id   = "${aws_api_gateway_rest_api.example.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.example.invoke_arn}"
}

// Criando a implantação do API Gateway.
// Para ativar a configuração, exponha a API em URL que pode ser usada para teste:

resource "aws_api_gateway_deployment" "example" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_integration.lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.example.id}"
  stage_name  = "test"
}

// Para testar a API criada e acessar a URL de teste, para facilitar o acesso utilizaremos esse comando:

output "base_url" {
  value = "${aws_api_gateway_deployment.example.invoke_url}"
}

// FIM