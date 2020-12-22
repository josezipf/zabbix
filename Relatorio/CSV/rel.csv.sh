#!/bin/bash
# rel_hosts_csv.sh
#
# Versão 1: Script para gerar relatório de hosts monitorados pela ferramenta ZABBIX para um arquivo CSV
#
#
# Ex: ./rel_hosts_csv.sh usuario senha
#
# Requisitos: pacote jq deve estar instalado 
#
# Para instalar no Ubuntu -> apt install jq
#
# Evandro José Zipf, Março 2020

#------------------------------------[ INFORMAÇÔES ZABBBIX ]-----------------------------------------------------------------------#

# Caminho para conectar no seu Zabbix via API
API="https://ipdoseuzabbix/zabbix/api_jsonrpc.php"
USUARIO="$1"
SENHA="$2"

#-----------------------------------------[ INICIO ]-------------------------------------------------------------------------------#


# Verifica se foi passado usuário e senha no script

[ $# -ne 2 ] && {

	echo "Informa usuário e senha para conectar na API do Zabbix" 
	exit 0;
}

#
# Autenticação na API via JSON
JSON='
    {
        "jsonrpc": "2.0",
        "method": "user.login",
        "params": {
            "user": "'$USUARIO'",
            "password": "'$SENHA'"
        },
        "id": 0
    }
    '
# Armazena o TOKEN de autenticação
TOKEN=$(curl -s -k -X POST -H "Content-Type:application/json" -d "$JSON" "$API" | cut -d '"' -f8)


# Consulta via JSON os host que estão cadastrados e com monitoramento ativo
HOSTS='
   {
    
   "jsonrpc": "2.0",
   "method": "host.get",
   "params": { 
               "output": ["hostid","host"],
	       	     "monitored_hosts": 1
    },
    "auth": "'$TOKEN'",
    "id": 1
   
   }
    '

# Consulta via JSON os host que estão cadastrados e com monitoramento ativo
INTERFACE='
   {
    
   "jsonrpc": "2.0",
   "method": "hostinterface.get",
   "params": { 
               "output": ["hostid","ip","type"]
    },
    "auth": "'$TOKEN'",
    "id": 1
   
   }
    '


# Executa e armazena os hosts dentro da variável 
hosts=$(curl -s -k -X POST -H "Content-Type:application/json" -d "$HOSTS" "$API")
# Executa e armazena os ips dentro da variável
interfaces=$(curl -s -k -X POST -H "Content-Type:application/json" -d "$INTERFACE" "$API")

# Imprimi os hosts em formato JSON e envia para o Jq tratar array e criar o CSV
echo "$hosts" |jq -r '.result[] | [.hostid, .host] | @csv' |sort  > rel_host.csv
# Imprimi os ips em formato JSON e envia para o Jq tratar array e criar o CSV
echo "$interfaces" |jq -r '.result[] | [.hostid, .ip, .type] | @csv'|\
sort -t, --key=1,2 -u|sed -E 's/"[0-9]{5}",//g' > rel_interfaces.csv

# Junta tudo num único arquivo
paste -d\, rel_host.csv rel_interfaces.csv > rel_final.csv

# Troca o que for 1 para agente e 2 para SNMP, após insere cabeçalho.
sed -i 's/\"1\"/AGENTE/;s/\"2\"/SNMP/' rel_final.csv && cat - rel_final.csv <<< "\"IDHOST\",\"HOSTNAME\",\"IP\",\"TIPO\"" > rel_final_completo.csv

# Relatório realizado com sucesso
echo "Relatório gerado com sucesso veja rel_final_completo.csv"
