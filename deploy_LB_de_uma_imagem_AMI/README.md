Realizando Deploy de Auto Scaling Groups e Elastic Load Balancers na AWS com Terraform


Arquitetura da nossa Stack:
- O projeto irá contar com as seguintes features:

> Elastic Load Balancer (ELB) 
> Auto Scaling Group com Launch Configuration 
> Instâncias em Multi-AZ
> Scaling Policy para Up e Down 


TerrForm com user-data
-  instalar o apache e modificar o index do servidor

user-data/bootstrap.sh


Testando
- Acessar o DNS do nosso Load Balancer para verificar o deploy da nossa instância
