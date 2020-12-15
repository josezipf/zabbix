#!/bin/bash
# contagem_onu_fiber.sh
#
# Versão 1: Script para coleta total de ONU online, offline e total para OLT Fiberhome 
#
# Ex: ./contagem_onu_fiber.sh
#
# Requisitos: Zabbix e pacote jq instalado.
#
#
# Evandro José Zipf, Dezembro 2020
#
#------------------------------------[ INFORMAÇÔES ZABBBIX ]-------------------------------------------------------------------------------------#

# Caminho para conectar no seu Zabbix via API
API="http://127.0.0.1/noto/api_jsonrpc.php"
USUARIO="usuario"
SENHA="senha"


	# Mensagem de uso do programa que é enviada para o usuário como ajuda.
	MENSAGEM_USO="
	   Uso: $(basename "$0")[-discovery|-V|-h]

	   	 -total   contagem de total de onu
	     -online  contagem de onu online
	     -offline contagem de onu offline
	     -V mostra versão do script
	     -h mostra ajuda

	     Ex: ./contagem_onu_fiber.sh -online id_do_host_zabbix
	     Ex: ./contagem_onu_fiber.sh -offline id_do_host_zabbix
   	     Ex: ./contagem_onu_fiber.sh -total id_do_host_zabbix


	   "
	# Mensagem para informar usuário que o comando mtr não está instalado.
	MENSAGEM_JQ="Pacote jq não instalado, 

		instale com apt install jq em caso de Ubuntu/Debian ou 
		instale com yum install jq para RedHat Centos"

	# Verifica se está instalado o comando jq
	if ! command -v jq > /dev/null
        then
        	echo "$MENSAGEM_JQ"
        	exit 0;
        fi

#--------------------------------------------[Funções]--------------------------------------------------------------------------------------------#

   autenticacao()
   {
    			# Autenticação na API Zabbix

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
                retorno_autenticacao=$(curl -s -X POST -H "Content-Type:application/json" -d "$JSON" "$API" | cut -d '"' -f8)

                # Retorna o token de autenticação
	            echo "$retorno_autenticacao"
    }


    busca_item() 
    {
	# Consulta via API todos os itens que contenham o nome "Status ONU" de um host específico.

		TOKEN=$(autenticacao)

		local host=$2

                JSON_ITEM='
                    {
                           "jsonrpc": "2.0",
                           "method": "item.get",
                           "params": {
                                       "output": "extend",
                                       "hostids": "'$host'",
                                       "sortfield": "name",
                                       "search": {
                                                   "name": "Status ONU"
                                                 }

                                     },

	                        "auth": "'$TOKEN'",
                            "id": 1

                    }
                    '
				retorno_item=$(curl -s -X POST -H "Content-Type:application/json" -d "$JSON_ITEM" "$API")
				echo "$retorno_item"
	}

#-------------------------------------------------------[ INICIO ]-------------------------------------------------------------------------------#


				    # Precisa passar exatamente 2 parâmetros
	  			    [ $# -ne 2 ] && 
	  				{ 
	  				  echo "Informe 2 parâmetros!" 
	  				  exit 0;
	  				}

					case "$1" in
				        
				        -online) online=1
						;;

					-offline) offline=1
						;;

					-total) total=1
						;;

				        -h|--help)
				            echo "$MENSAGEM_USO"
				            exit 0
				        ;;
				        
				        -V|--version)
				            echo -n $(basename "$0")
				            # Extrai a versão diretamente dos cabeçalhos do programa
				            grep '^# Versão' "$0"| tail -1| cut -d: -f1 |tr -d \#
				            exit 0

				        ;;        
				           
				         *)  # Opção inválida
				            if test -n "$1"
				            then
				                echo Opção invalida: $1
				                exit 1
				            fi
				        ;;
				    esac

				    # Chama a função de autenticação
				    auth=$(autenticacao)

 				    # Armazena dados da autenticação
		   		    auth=$(echo "$auth" |wc --chars)
 		  
				    # Se falhar autenticação encerra o script e informa o usuário
				    if [ "$auth" -lt 32 ]; then

						echo "Erro na autenticação da API do Zabbix"
						exit 0;

				    fi

				    # Coleta o total de onus coletadas via API analisando um arquivo csv gerado pelo jq
				    test "$total" = 1 && r_item=$(busca_item 0 $2) && echo "$r_item" |jq -r '.result[] | [.lastvalue] | @csv' > /tmp/rel_valores_$$.csv \
				    && wc -l < /tmp/rel_valores_$$.csv

				    # Coleta somente as ONU que tiverem valor 1 analisando um arquivo csv gerado pelo jq
				    test "$online" = 1 && r_item=$(busca_item 0 $2) && echo "$r_item" |jq -r '.result[] | [.lastvalue] | @csv' > /tmp/rel_valores_$$.csv \
				    && grep "1" /tmp/rel_valores_$$.csv|wc -l

				    # Coleta somente as ONU que tiverem valor 2 analisando um arquivo csv gerado pelo jq
				    test "$offline" = 1 && r_item=$(busca_item 0 $2) && echo "$r_item" |jq -r '.result[] | [.lastvalue] | @csv' > /tmp/rel_valores_$$.csv \
				    && grep "2" /tmp/rel_valores_$$.csv|wc -l

				    # Remove arquivo temporário
				    rm /tmp/rel_valores_$$.csv
