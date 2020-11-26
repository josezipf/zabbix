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

# Informa o total de saltos do comando mtr
total_rota=9
nomehost="$2"
destino="$3"
arq_temp="/tmp/rota_"$nomehost".txt"

# Inicia as chaves desativadas
discovery=0
ip=0
snt=0
mtr=0
asn=0

	# Mensagem de uso do programa que é enviada para o usuário como ajuda.
	MENSAGEM_USO="
	   Uso: $(basename "$0")[-discovery|-V|-h]

	     -discovery realiza a descoberta de rotas e gera em formato JSON para LLD Zabbix
	     -ip coleta o ip da rota
	     -snt coleta o snt da rota
	     -asn coleta asn da rota
	     -V mostra versão do script
	     -h mostra ajuda

	     Ex: ./zbx_mrt.sh -discovery
	     Ex: ./zbx_mrt.sh -ip nomehost numero_da_rota
	     Ex: ./zbx_mrt.sh -snt nomehost numero_da_rota
	     Ex: ./zbx_mrt.sh -asn nomehost numero_da_rota
	   "

	
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

  						# Não deixa passar mais de 1 parametro
  						[ $# -ne 1 ] && 
  						{ 
  							echo "Informe somente 1 parâmetro!" 
  							exit 0;
  						}
			 
  					   	# Trata primeiro elemento do JSON
						PRIMEIRO_ELEMENTO=1


						# Criar o cabeçalho padrão do JSON
						printf "{";
						printf "\"data\":[";

							    for numero_rota in $(seq "$total_rota")
							    do
							        # Verifica o primeiro elemento
							        if [ $PRIMEIRO_ELEMENTO -ne 1 ]; then
							                printf ","
							        fi

							        # Não coloca "," caso seja o ultimo dado no JSON
							        PRIMEIRO_ELEMENTO=0

							        # Cria o JSON de cada DATABASE
							        printf "{"
							        printf "\"{#ROTA}\":\"$numero_rota\""
							        printf "}"
							    done
						
						# Finaliza o Formato JSON
						printf "]";
						printf "}";

						# Encerra
						exit 0;
  					fi

  					# Obriga passar 3 parâmetros se as chaves estiverem ligadas
  					[ $# -ne 3 ] && 
  					{ 
  						echo "Informe 3 parâmetros!" 
  						exit 0;
  					}


  					# Executa o comando mtr e armazena num arquivo temporário, retorna 0 se comando falhar
			  		test "$mtr" = 1 && rota=$(mtr -w --no-dns -z "$destino") && \
			  		echo "$rota" |tr -s ' '|sed  's/^\s//g;s/\.\s/,/g;s/\s/,/g' > "$arq_temp" |echo 1

			  		# Coleta o valor da ASN do arquivo temporário de acordo com o host monitorado
			  		test "$asn" = 1 && grep "^$3\," "$arq_temp" |cut -d\, -f2

			  		# Coleta o valor da IP do arquivo temporário de acordo com o host monitorado
			  		test "$ip" = 1  && grep "^$3\," "$arq_temp" |cut -d\, -f3

			  		# Coleta o valor da SNT do arquivo temporário de acordo com o host monitorado
			  		test "$snt" = 1 && grep "^$3\," "$arq_temp" |cut -d\, -f5
								

