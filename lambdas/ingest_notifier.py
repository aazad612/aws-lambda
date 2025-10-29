import os, json, uuid, time, boto3
from urllib.parse import unquote_plus

DDB_TABLE = 'media-intake-MediaCatalog'

s3  = boto3.client("s3")
ddb = boto3.resource("dynamodb").Table(DDB_TABLE)

def lambda_handler(event, context):
    # S3 Put events may contain multiple records
    for rec in event.get("Records", []):
        if rec.get("eventSource") != "aws:s3":  # safety
            continue

        bucket = rec["s3"]["bucket"]["name"]
        key    = unquote_plus(rec["s3"]["object"]["key"])
        if key.endswith("/"):  # skip folder placeholders
            continue

        # HEAD to enrich metadata (size, content-type)
        head = s3.head_object(Bucket=bucket, Key=key)
        size = head.get("ContentLength", 0)
        ctype = head.get("ContentType", "application/octet-stream")

        asset_id = str(uuid.uuid4())
        today = time.strftime("%Y-%m-%d", time.gmtime())

        item = {
            "assetId": asset_id,            # PK (make sure your table uses this as HASH key)
            "ingestDate": today,            # SK (make sure your table uses this as RANGE key)
            "bucket": bucket,
            "rawKey": key,
            "sizeBytes": size,
            "contentType": ctype,
            "status": "RECEIVED",
            "source": "s3:event",
            "ts": int(time.time())
        }

        ddb.put_item(Item=item)

    return {"ok": True, "records": len(event.get("Records", []))}
