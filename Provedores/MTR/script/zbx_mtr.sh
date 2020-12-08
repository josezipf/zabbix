#!/bin/bash
# zbx_mrt.sh
#
# Versão 1: Script para coleta de rotas via comando mtr para Zabbix.
#
# Ex: ./zbx_mrt.sh -discovery
#
# Requisitos: Comando mtr
#
#
# Evandro José Zipf, Novembro 2020
#-------------------------------------------------------[ INICIO ]-------------------------------------------------------------------------------#

# Variáveis
total_valores=60
nomehost="$2"
destino="$3"
arq_temp="/tmp/rota_"$nomehost".txt"

# Inicia as chaves desativadas
discovery=0
ip=0
snt=0
mtr=0
asn=0

#------------------------------------[ INFORMAÇÔES ZABBBIX ]-------------------------------------------------------------------------------------#

# Caminho para conectar no seu Zabbix via API
API="http://127.0.0.1/noto/api_jsonrpc.php"
USUARIO="api"
SENHA="api@2020"


	# Mensagem de uso do programa que é enviada para o usuário como ajuda.
	MENSAGEM_USO="
	   Uso: $(basename "$0")[-discovery|-V|-h]

	     -discovery realiza a descoberta de rotas e gera em formato JSON para LLD Zabbix
	     -ip coleta o ip da rota
	     -snt coleta o snt da rota
	     -asn coleta asn da rota
	     -total coleta o total de saltos percorridos
	     -V mostra versão do script
	     -h mostra ajuda

	     Ex: ./zbx_mrt.sh -discovery nomehost
	     Ex: ./zbx_mrt.sh -ip nomehost numero_da_rota
	     Ex: ./zbx_mrt.sh -snt nomehost numero_da_rota
	     Ex: ./zbx_mrt.sh -asn nomehost numero_da_rota
	   "
	# Mensagem para informar usuário que o comando mtr não está instalado.
	MENSAGEM_MTR="Pacote mtr não instalado, 

		instale com apt install mtr em caso de Ubuntu/Debian ou 
		instale com yum install mtr para RedHat Centos"

	# Mensagem para informar usuário que o comando mtr não está instalado.
	MENSAGEM_JQ="Pacote jq não instalado, 

		instale com apt install jq em caso de Ubuntu/Debian ou 
		instale com yum install jq para RedHat Centos"

	# Verifica se está instalado o comando mrt
	if ! command -v mtr > /dev/null
        then
           echo "$MENSAGEM_MTR"
           exit 0;
        fi

       # Verifica se está instalado o comando mrt
	if ! command -v jq > /dev/null
        then
          echo "$MENSAGEM_JQ"
          exit 0;
        fi

	# Se não passar nenhum arqgumento, mostra mensagem de ajuda
	[ "$1" ] || {

		echo
		echo "$MENSAGEM_USO"
		exit 0

	}


					case "$1" in
				        
				        # Opções de ligam e desligam chaves
				        -discovery) discovery=1
						;;

						-ip) ip=1
						;;

						-snt) snt=1
						;;

						-mtr) mtr=1
						;;

						-asn) asn=1
						;;

						-loss) loss=1
						;;

						-last) last=1
						;;

						-avg) avg=1
						;;

						-best) best=1
						;;

						-wrst) wrst=1
						;;

						-stdev) stdev=1
						;;

						-total) total=1
						;;

						-totalip) totalip=1
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

					if [ "$discovery" = 1 ]; then

	  					# Precisa passar exatamente 2 parâmetros
	  					[ $# -ne 2 ] && 
	  					{ 
	  							echo "Informe somente 2 parâmetros!" 
	  							exit 0;
	  					}

	  					# Verifica se arquivo com as rotas existe.
	  					if [ -f "$arq_temp" ]
	  					then

	  					   	# Trata primeiro elemento do JSON
							PRIMEIRO_ELEMENTO=1

							numero_rota=$(grep -o '^[0-9]\+' "$arq_temp")


							# Criar o cabeçalho padrão do JSON
							printf "{";
							printf "\"data\":[";

								    for rota in $numero_rota
								    do
								        # Verifica o primeiro elemento
								        if [ $PRIMEIRO_ELEMENTO -ne 1 ]; then
								                printf ","
								        fi

								        # Não coloca "," caso seja o ultimo dado no JSON
								        PRIMEIRO_ELEMENTO=0

								        # Cria o JSON de cada rota
								        printf "{"
								        printf "\"{#ROTA}\":\"$rota\""
								        printf "}"
								    done
							
							# Finaliza o Formato JSON
							printf "]";
							printf "}";

							# Encerra
							exit 0;
						else
							echo "Arquivo de rota não existe, rode primeiro Ex: ./zbx_mrt.sh -mrt nomehost google.com.br"
							exit 0;
						fi
	  				fi

	  				# Precisa passar exatamente 2 parâmetros
	  			    [ $# -ne 3 ] && 
	  				{ 
	  				  echo "Informe 3 parâmetros!" 
	  				  exit 0;
	  				}

  					# Executa o comando mtr e armazena num arquivo temporário
			  		test "$mtr" = 1 && rota=$(mtr -w --no-dns -z "$destino") && \
			  		echo "$rota" |tr -s ' '| tr \? 0 |sed  's/^\s//g;s/\.\s/,/g;s/\s/,/g' > "$arq_temp" && echo 1

			  		# Coleta o valor da ASN do arquivo temporário de acordo com o host monitorado
			  		if [ "$asn" = 1 ]; then
			  			
			  			r_asn=$(grep "^$3\," "$arq_temp" |cut -d\, -f2)

			  			# Se for nulo encerra
			  			if [ -z "$r_asn" ]; then

			  				echo 0
			  			    exit 1;

			  			fi 

			  			echo $r_asn;
			  		fi
			  		
			  		# Coleta o valor da IP do arquivo temporário de acordo com o host monitorado
			  		if [ "$ip" = 1 ]; then
			  			
			  			r_ip=$(grep "^$3\," "$arq_temp" |cut -d\, -f3)

			  			# Se for nulo encerra
			  			if [ -z "$r_ip" ]; then

			  				echo 0
			  				exit 1;

			  			fi

			  			echo $r_ip;
			  		fi
			  		
			  		# Coleta o valor da SNT do arquivo temporário de acordo com o host monitorado
			  		if [ "$snt" = 1 ]; then

			  			r_snt=$(grep "^$3\," "$arq_temp" |cut -d\, -f5)

			  			# Se for nulo encerra
			  			if [ -z "$r_snt" ]; then

			  				echo 0
			  			    exit 1;

			  			fi 

			  			echo $r_snt;
			  		fi

			  		# Coleta o valor loss do arquivo temporário de acordo com o host monitorado
			  		if [ "$loss" = 1 ]; then

			  			r_loss=$(grep "^$3\," "$arq_temp" |cut -d\, -f4| tr -d \%)

			  			# Se for nulo encerra
			  			if [ -z "$r_loss" ]; then

			  				echo 0
			  			    exit 1;

			  			fi 

			  			echo $r_loss;
			  		fi

			  		# Coleta o valor do last do arquivo temporário de acordo com o host monitorado
			  		if [ "$last" = 1 ]; then

			  			r_last=$(grep "^$3\," "$arq_temp" |cut -d\, -f6)

			  			# Se for nulo encerra
			  			if [ -z "$r_last" ]; then

			  				echo 0
			  			    exit 1;

			  			fi 

			  			echo $r_last;
			  		fi

			  		# Coleta o valor do avg do arquivo temporário de acordo com o host monitorado
			  		if [ "$avg" = 1 ]; then

			  			r_avg=$(grep "^$3\," "$arq_temp" |cut -d\, -f7)

			  			# Se for nulo encerra
			  			if [ -z "$r_avg" ]; then

			  				echo 0
			  			    exit 1;

			  			fi 

			  			echo $r_avg;
			  		fi

			  		# Coleta o valor do best do arquivo temporário de acordo com o host monitorado
			  		if [ "$best" = 1 ]; then

			  			r_best=$(grep "^$3\," "$arq_temp" |cut -d\, -f8)

			  			# Se for nulo encerra
			  			if [ -z "$r_best" ]; then

			  				echo 0
			  			    exit 1;

			  			fi 

			  			echo $r_best;
			  		fi

			  		# Coleta o valor do wrst do arquivo temporário de acordo com o host monitorado
			  		if [ "$wrst" = 1 ]; then

			  			r_wrst=$(grep "^$3\," "$arq_temp" |cut -d\, -f9)

			  			# Se for nulo encerra
			  			if [ -z "$r_wrst" ]; then

			  				echo 0
			  			    exit 1;

			  			fi 

			  			echo $r_wrst;
			  		fi

			  		# Coleta o valor do stdev do arquivo temporário de acordo com o host monitorado
			  		if [ "$stdev" = 1 ]; then

			  			r_stdev=$(grep "^$3\," "$arq_temp" |cut -d\, -f10)

			  			# Se for nulo encerra
			  			if [ -z "$r_stdev" ]; then

			  				echo 0
			  			    exit 0;

			  			fi 

			  			echo $r_stdev;
			  		fi

			  		# Coleta o total de saltos percorridos até o destino informado
			  		test "$total" = 1 && grep '^[0-9]\+\,' "$arq_temp"| wc -l

			  		# Coleta o total de alterações de destino por rota
			  		if [ "$totalip" = 1 ]; 
			  		then

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
							TOKEN=$(curl -s -X POST -H "Content-Type:application/json" -d "$JSON" "$API" | cut -d '"' -f8)


						    # Consulta via JSON o id do ITEM por host
							JSON='
							    {

							   "jsonrpc": "2.0",
							   "method": "item.get",
							   "params": {
							               "output": "extend",
							               "hostids": "'$3'",
							               "sortfield": "name",
							               "search": {
							                        "name": "(IP)"
							                }

							    },

							    "auth": "'$TOKEN'",
							    "id": 1

							   }
							    '

						    # Armazena em um arquivo os IDs dos itens que contém ips por host.    
                            r_item=$(curl -s -X POST -H "Content-Type:application/json" -d "$JSON" "$API")
                            # Coloca o retorno em arquivo CSV
                            echo "$r_item" |jq -r '.result[] | [.itemid, .key_, .name] | @csv' > /tmp/rel_itemid_$$.csv
                            # Extrair o ID do item da rota especifica
                            id_item=$(grep "Rota $2 " /tmp/rel_itemid_$$.csv |cut -d\" -f2)

							# Consulta histórico do item via JSON
                            JSON='
                                {

                               "jsonrpc": "2.0",
                               "method": "history.get",
                               "params": {
                                           "output": "extend",
                                           "history": 1,
                                           "itemids": "'$id_item'",
                                           "sortfield": "clock",
                                           "sortorder": "DESC",
                                           "limit": "'$total_valores'"
                                   	     },

                                "auth": "'$TOKEN'",
                                "id": 2
                                
                                }'

							# Armazena o histórico do item em arquivo, somente os valores
                            retorno=$(curl -s -X POST -H "Content-Type:application/json" -d "$JSON" "$API")
                            # Coloca o retorno em arquivo CSV
                            echo "$retorno"| jq -r '.result[] | [.value] | @csv' > /tmp/rel_resultado_$$.csv 2>/dev/null
                            # Extrair somente ipv6 ou ipv4                          
                            grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' /tmp/rel_resultado_$$.csv > /tmp/rel_resultado1_$$.csv
                            # Cria uma cópia para comparação e remove linha desnecessárias
                            cp /tmp/rel_resultado1_$$.csv /tmp/rel_resultado2_$$.csv
                            # Remove primeira linha do arquivo com resultado 2 para comparação
                            sed -i '1d' /tmp/rel_resultado2_$$.csv
                            # Remove as aspas dos arquivos
                            sed -s -i -E 's/\"//g' /tmp/rel_resultado1_$$.csv /tmp/rel_resultado2_$$.csv
                            # Criar um único arquivo para comparação
                            paste -d\; /tmp/rel_resultado1_$$.csv /tmp/rel_resultado2_$$.csv > /tmp/rel.final$$.csv


							i=0						
								    # Faz o loop no arquivo /tmp/rel.final$$.csv e compara cada valor
							        while IFS=\; read -r valor1 valor2;
							        do
							        	    # Verifica se o segundo valor é nulo
							        		if [ -z $valor2 ]; then

							        			valor2="$valor1"

							        	 	fi
							        	 	# Se for diferente entra no contador
							        	 	if [ "$valor1" != "$valor2" ]; then


							                    i=$((i + 1))                        

							                fi


							        done < "/tmp/rel.final$$.csv"

							# Total de alterações
							echo $i
							# Remove os arquivos temporários
							rm /tmp/rel_itemid_$$.csv /tmp/rel_resultado_$$.csv /tmp/rel_resultado1_$$.csv /tmp/rel_resultado2_$$.csv /tmp/rel.final$$.csv

			  		fi
