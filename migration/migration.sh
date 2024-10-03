## DUMP:      https://www.mongodb.com/docs/database-tools/mongodump/#mongodb-binary-bin.mongodump
## RESTORE:   https://www.mongodb.com/docs/database-tools/mongorestore/#mongodb-binary-bin.mongorestore

source ./.env

# 1. dump db from source
mongodump "mongodb+srv://$SOURCE_MONGO_CLUSTER" \
  --username=$SOURCE_USERNAME \
  --password=$SOURCE_PASSWORD \
  --db=$SOURCE_DB \
  --out=./dump

# 2. restore db to target
mongorestore "mongodb+srv://$TARGET_MONGO_CLUSTER" \
  --username=$TARGET_USERNAME \
  --password=$TARGET_PASSWORD \
  --nsFrom="$SOURCE_DB.*" \
  --nsTo="$TARGET_DB.*" \
  ./dump

# 3. cleanup
rm -r ./dump/$SOURCE_DB
