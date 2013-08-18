curl -X PUT http://127.0.0.1:5984/portal_test/users -d '
{
  "userList": ["Clark", "Lex", "Bruce", "Diana"]
}'

curl -X PUT http://127.0.0.1:5984/portal_test/1 -d '
{
    "type": "post",
    "user": "Clark",
    "postDate": "01/15/2000",
    "gpa": 3.00,
    "title": "Test Clark 1",
    "body": "This is test 1 by Clark."
}'

curl -X PUT http://127.0.0.1:5984/portal_test/2 -d '
{
    "type": "post",
    "user": "Clark",
    "postDate": "01/16/2000",
    "gpa": 3.00,
    "title": "Test Clark 2",
    "body": "This is test 2 by Clark."
}'

curl -X PUT http://127.0.0.1:5984/portal_test/3 -d '
{
    "type": "post",
    "user": "Lex",
    "postDate": "01/16/2000",
    "gpa": 3.90,
    "title": "Test Lex 1",
    "body": "This is test 1 by Lex."
}'

curl -X PUT http://127.0.0.1:5984/portal_test/4 -d '
{
    "type": "post",
    "user": "Bruce",
    "postDate": "01/17/2000",
    "gpa": 4.00,
    "title": "Test Bruce",
    "body": "Im Batman."
}'

curl -X PUT http://127.0.0.1:5984/portal_test/5 -d '
{
    "type": "post",
    "user": "Diana",
    "postDate": "01/18/2000",
    "gpa": 3.50,
    "title": "Test Diana",
    "body": "This is test 1 by Diana."
}'

curl -X PUT http://127.0.0.1:5984/portal_test/dateArray -d '
{
  "dates": ["01/01/2001", "01/02/2001", "01/03/2001", "01/04/2001"]
}'

curl -X PUT http://127.0.0.1:5984/portal_test/idsArray -d '
{
  "secIDs" : [
    { "FIRST_NAME": "Clark", "LAST_NAME": "Kent",  "HANDLE": "Superman" },
    { "FIRST_NAME": "Bruce", "LAST_NAME": "Wayne", "HANDLE": "Batman" },
    { "FIRST_NAME": "Diana", "LAST_NAME": "",      "HANDLE": "Wonder Woman" },
    { "FIRST_NAME": "Lex",   "LAST_NAME": "Luther", "HANDLE": "villain" }
  ]
}'
