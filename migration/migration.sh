## DUMP:      https://www.mongodb.com/docs/database-tools/mongodump/#mongodb-binary-bin.mongodump
## RESTORE:   https://www.mongodb.com/docs/database-tools/mongorestore/#mongodb-binary-bin.mongorestore

source ./.env

# 1. dump db from source
mongodump "mongodb+srv://$SOURCE_MONGO_CLUSTER"
\ --username=$SOURCE_USERNAME
\  --password=$SOURCE_PASSWORD
\  --db=$SOURCE_DB
\  --out=./dump
\  --excludeCollection=sessions
\  --excludeCollection=accounts
\  --excludeCollection=orders
\  --excludeCollection=orderitems
\  --excludeCollection=assetitems
\  --excludeCollection=cards_13e5a329-52e8-45bd-9887-537753adbeee
\  --excludeCollection=loyalty_members
\  --excludeCollection=loyalty_transactions
\  --excludeCollection=events_history
\  --excludeCollection=flowsobjectsnumbers
\  --excludeCollection=sequences

# 2. restore db to target
mongorestore "mongodb+srv://$TARGET_MONGO_CLUSTER" \
  --username=$TARGET_USERNAME \
  --password=$TARGET_PASSWORD \
  --nsFrom="$SOURCE_DB.*" \
  --nsTo="$TARGET_DB.*" \
  --drop \
  ./dump

# 3. cleanup
rm -r ./dump/$SOURCE_DB
