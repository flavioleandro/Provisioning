# Fargate with Terraform

Example repository to deploy an ECS cluster hosting a web application.

Docker_with_ECS_and_Fargate



Implementar com Terraform, uma imagem simples em um cluster do ECS dom Fargate

- Arquitetura
--Implementar uma VPC com uma sub-rede privada e uma sub-rede pública. Um cluster do ECS na sub-rede privada, executando o contêiner do docker. Uma solicitação de balanceamento de carga do ALB para o cluster ECS.

link >> file:///C:/Users/flavio.leandro/Downloads/_post_aws-fargate_architecture.svg

-- Network
        Criar uma VPC e sub-redes privadas e públicas, cada uma em um AZ diferente
        Encaminhar o tráfego de sub-rede pública através do IGW
        Criar um gateway NAT com um EIP para cada sub-rede privada para obter conectividade com a Internet
        Encaminhamento do tráfego não local através do gateway NAT para a Internet
        Associe explicitamente as tabelas de rotas recém-criadas às sub-redes privadas (para que elas não sejam padronizadas para a tabela de rotas principal)


-- Alta disponibilidade 

    --ECS (Elastic Container Service)
        Implantar o cluster do ECS para ser executado em pelo menos 2 Zonas de Disponibilidade (AZs)
        O balanceador de carga também precisa de pelo menos duas sub-redes públicas em diferentes AZs.
        O tráfego para o cluster do ECS deve vir somente do ALB

    --ALB (Application Load Balancer)
        Redirecionar (rotear) todo o tráfego do ALB para o o cluster do ECS

    --Fargate
        O Fargate permite ligar um IP público aos contêineres iniciados, permitindo que você use apenas uma sub-rede pública.


vi 