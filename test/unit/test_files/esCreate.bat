curl -XPUT http://127.0.0.1:5984/portal_test

curl -XPUT 'localhost:9200/portal_test/' -d '
{
  "mappings": {
    "_default_" : {
        "date_formats" : ["yyyy-MM-dd", "yyyy/mm/dd", "MM/dd/yyyy", "MM-dd-yyyy", 
          "date_optional_time"]
    }
  }
}'

curl -XPUT 'localhost:9200/_river/portal_test/_meta' -d '{
    "type" : "couchdb",
    "couchdb" : {
        "host" : "localhost",
        "port" : 5984,
        "db" : "portal_test",
        "filter" : null
    },
    "index" : {
        "index" : "portal_test",
        "type" : "portal_test",
        "bulk_size" : "100",
        "bulk_timeout" : "10ms"
    }
}'
