# CHAT: Este ficheiro aqui    psps-webapp/src/store/json-store.ts    Se calhar podemo... [2026-03-19T22:10:05+00:00] (pt)
Este ficheiro aqui



psps-webapp/src/store/json-store.ts



Se calhar podemos já fazer um ordem, porque tem já +1200 linhas



e dividir em dois,



um store (chamado "pulse schedule" para manter o nome dos objetos que já estão lá)

com a estructura que vrecebemos e enviamos do psps protocol



e um outro "confic tree" para todo o quer seja relacionado com write e read da estrutura propia da web app

O que achas,m da para fazer agora? temos que combinar poara no ter muitos conflitos na branches quer estamos a trabalhar
--------
Este ficheiro, `psps-webapp/src/store/json-store.ts`, já tem mais de 1200 linhas.

Talvez seja uma boa altura para o reorganizar e dividir em dois, por exemplo:

1.  Um *store* (que poderíamos chamar "pulse schedule" para manter a nomenclatura dos objetos existentes) para gerir a estrutura que recebemos e enviamos através do protocolo PSPS.
2.  E um outro *store* ou "config tree" (ou "árvore de configuração") para tudo o que estiver relacionado com as operações de escrita e leitura da estrutura própria da *web app*.

O que achas? Dá para fazermos isto agora? Teremos de combinar para não termos muitos conflitos nas *branches* em que estamos a trabalhar.
--------

# CHAT: list all files in Downloads folder [2026-03-19T22:28:45+00:00] (%shell%)
list all files in Downloads folder
--------
ls -la ~/Downloads
--------

# CHAT: estamos testeando eso [2026-03-20T09:51:45+00:00] (pt)
estamos testeando eso
--------
Estamos a testar isso.
--------

