createdb:
	docker run --name chat_sys_db -e MYSQL_ROOT_PASSWORD=root \
	-e MYSQL_DATABASE=rails_chat_system \
	-p 3306:3306 -d mysql:8.0

runelasticsearch:
	docker run -p 9200:9200 --name elastic_search -e "ES_JAVA_OPTS=-Xms2g -Xmx2g"  -e "bootstrap.memory_lock=true" -e "discovery.type=single-node" -d docker.elastic.co/elasticsearch/elasticsearch:7.17.18