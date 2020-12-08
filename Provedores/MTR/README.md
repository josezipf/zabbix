Esse script realiza o monitoramento de rotas atráves do comando mtr e o seu resultado é enviado para o Zabbix. Atráves de external check


# Requisitos de pacotes: Instalar conforme seu sistema operacional

# Ubuntu/Debian
apt install jq mtr

# RedHat/Centos
yum install jq mtr

# Ajustar dentro do script caminho para conectar no seu Zabbix via API. Criar usuário e senha no Zabbix. O Usuário deve ter permissão de pelo menos leitura do host cadastrado no Zabbix, no qual será realizado o monitoramento.
API="http://127.0.0.1/noto/api_jsonrpc.php"
USUARIO="usuario"
SENHA="senha"

# Rota de teste padrão está para o Google
Você pode modificar alterando a macro {$DESTINO} dentro do template ou a nível de host.

# Alterar timeout dentro de zabbix_server.conf
Para rodar a coleta dos dados do mtr o script executa um comando, que faz o trajeto das rotas. Esse, comando demora um tempo de geralmente 15 segundos. Portanto,
altere conforme necessário para seu ambiente. Você também, pode ajustar item para ser executado o comando através da chave system.run do agente. Esse método é 
recomendado(opcional), se feito realizado atráves da chave system.run não é necessário alterar timeout do zabbix_server.conf

Timeout=15

# Colocar script dentro do diretório Externalscripts do Zabbix. Default: /usr/lib/zabbix/externalscripts
# Permissões para usuário zabbix
chown zabbix.zabbix zbx_mtr.sh
chmod +x zbx_mtr.sh

# Importar template e atrelar ao host no Zabbix







