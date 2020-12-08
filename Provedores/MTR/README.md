# Requisitos de pacotes: Instalar conforme seu sistema operacional

# Ubuntu/Debian
apt install jq mtr

# RedHat/Centos
yum install jq mtr

# Ajustar dentro do script caminho para conectar no seu Zabbix via API
# Cria usuário e senha no Zabbix para conectar na API.
# Usuário deve ter permissão de pelo menos leitura do host cadastrado no Zabbix.
API="http://127.0.0.1/noto/api_jsonrpc.php"
USUARIO="api"
SENHA="api@2020"

