#!/bin/bash

### Chamados sem reinserção de Grupo após alteração dos campos Prioridade e Tipo ###

# Variáveis
MYSQL=$(which mysql)
DATABASE=glpi
USER='user'
PASS='senha'
IP=x.x.x.x
DBCONNECT=$(echo $MYSQL -h$IP -u$USER -p$PASS $DATABASE)

# Query que pega os chamados que houveram alterações nos últimos dias

QUERY=$($DBCONNECT 2> /dev/null << EOF
SELECT l.id,
t.entities_id AS ID_ENTIDADE,
e.completename AS ENTIDADE,
l.items_id AS CHAMADO,
t.status AS STATUS,
l.user_name AS ALTERADO_POR,
l.date_mod AS DATA_ALT,
l.old_value AS VALOR_OLD,
l.new_value AS VALOR_NEW,
l.id_search_option AS PRIORIDADE
FROM glpi_logs l
LEFT JOIN glpi_tickets t
ON l.items_id=t.id
LEFT JOIN glpi_entities e
ON e.id=t.entities_id
WHERE e.completename LIKE "%Professional%"
AND t.status <> 6
AND l.itemtype = 'Ticket'
AND l.id_search_option = 3
AND l.date_mod > '2020-04-01 00:00:00'
union
SELECT l.id,
t.entities_id AS ID_ENTIDADE,
e.completename AS ENTIDADE,
l.items_id AS CHAMADO,
t.status AS STATUS,
l.user_name AS ALTERADO_POR,
l.date_mod AS DATA_ALT,
l.old_value AS VALOR_OLD,
l.new_value AS VALOR_NEW,
l.id_search_option AS PRIORIDADE
FROM glpi_logs l
LEFT JOIN glpi_tickets t
ON l.items_id=t.id
LEFT JOIN glpi_entities e
ON e.id=t.entities_id
WHERE e.completename LIKE "%Professional%"
AND t.status <> 6
AND l.itemtype = 'Ticket'
AND l.linked_action = 15
AND l.date_mod > '2020-05-01 00:00:00'
AND l.itemtype_link = 'Group'
union
SELECT l.id,
t.entities_id AS ID_ENTIDADE,
e.completename AS ENTIDADE,
l.items_id AS CHAMADO,
t.status AS STATUS,
l.user_name AS ALTERADO_POR,
l.date_mod AS DATA_ALT,
l.old_value AS VALOR_OLD,
l.new_value AS VALOR_NEW,
l.id_search_option AS PRIORIDADE
FROM glpi_logs l
LEFT JOIN glpi_tickets t
ON l.items_id=t.id
LEFT JOIN glpi_entities e
ON e.id=t.entities_id
WHERE e.completename LIKE "%Professional%"
AND t.status <> 6
AND l.itemtype = 'Ticket'
AND l.id_search_option = 14
AND l.date_mod > '2020-05-01 00:00:00'
ORDER BY 'CHAMADO',id;
EOF
)

# Trazer os chamados que contenham os valores 14 ou 3 na coluna Prioridade

RESULT=$(echo "$QUERY" | sed -e 's/\t/; /g' | awk -F';' '{print $4, $10}' | egrep -w '14|3' | awk '{print $1}' | uniq)

# Trazer todos os chamados da QUERY que sofreram alteração nos campos 14 e 13

RESULT2=$(for i in $(echo "$RESULT"); do echo "$QUERY" | sed -e 's/\t/; /g' | awk -F';' '{print $1, $3, $4, $6, $7, $9, $10}' | egrep -w $i; done)

# Ordenar por ID e Chamado

RESULT3=$(echo "$RESULT2" | sed -e 's/  /;/g' | sort -r -t ';' -k3,3)

# Traz as ultimas ocorrencias que houveram alteração do Tipo(14) e Prioridade(3)

for i in $(echo "$RESULT");
do
echo "$RESULT3" | grep $i | egrep -B10 -m1 ';14|;3' | grep -iq contrato
if [ $? = 1 ];
then
echo "$RESULT3" | grep $i | egrep -B10 -m1 ';14|;3' >> /tmp/ReinserirContrato;
fi
done

RESULT4=$(cat /tmp/ReinserirContrato | awk -F';' '{print $3, $5, $4}')

# Guarda Resultado

RESULT5=$(echo "$RESULT4" | sed 's/(.*)//g' | sort -u -t ' ' -k1,1 | sed 's/ /\t/1' |  sed 's/ /\t/2')

echo "$RESULT5"

# Enviar e-mail

TITULO="CHAMADO DATA_ALTERACAO ALTERADO_POR"
export smtpserver="outlook.office365.com:587"
export smtplogin="email@email.com.br"
export smtppass='senha'
export smtpemailfrom="email@email.com.br"
export emailto="email@email.com.br"
export subject="CHAMADOS SEM A REINSERÇÃO DO GRUPO APÓS ALTERAÇÃO DE CAMPOS"
export body="Boa tarde, \n\nSegue report atualizado para atuacao.\n\n $(echo $TITULO | sed 's/ /        /g')\n"$RESULT5" \n\nAtenciosamente,\nGrupo"

sendemail -o tls=yes -f $smtpemailfrom -t "$emailto" -u "$subject" -m "$body" -s $smtpserver -xu $smtplogin -xp $smtppass
echo "$smtpemailfrom" "$emailto" "$subject" "$body" > /tmp/log-email-reisercao

# Exclui arquivo

rm -f /tmp/ReinserirContrato
