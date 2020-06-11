# glpi_reinsercao_grupo_contrato
Script que retorna todos os chamados do sistema GLPI que não foi reinserido grupo de contrato após alteração dos campos Prioridade e Tipo.

Esse script foi uma necessidade interna devido um problema na ferramenta ITSM que ocorria quando era alterado certos campos dos chamados, impactando o cálculo correto do SLA.

O script basicamente busca em determinado período por chamados que tiveram esses campos alterados. Ao encontrar os chamados que se enquadram nos filtros estabelecidos é enviado um e-mail para os responáveis com uma lista informando quais chamados devem ser aplicados a reinserção do grupo de contrato. 
