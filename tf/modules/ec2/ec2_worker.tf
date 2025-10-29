# modules/ec2/ec2_worker.tf

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["137112412989"]
  filter { 
    name = "name" 
    values = ["al2023-ami-*-x86_64"] 
    }
}

locals {
  worker_subnet_id = var.private_subnet_ids[0]
}

resource "aws_instance" "worker" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = local.worker_subnet_id
  vpc_security_group_ids      = [aws_security_group.worker_sg.id]
  key_name                    = aws_key_pair.default.key_name
  iam_instance_profile        = aws_iam_instance_profile.worker_profile.name
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail
    dnf update -y
    dnf install -y python3-pip awscli jq
    pip3 install boto3 pillow psycopg2-binary

    cat >/opt/worker.py <<'PY'
import os, uuid, mimetypes, json, boto3, time
import psycopg2

RAW_BUCKET       = os.getenv("RAW_BUCKET")
PROCESSED_BUCKET = os.getenv("PROCESSED_BUCKET")
DDB_TABLE        = os.getenv("DDB_TABLE")
RDS_ENDPOINT     = os.getenv("RDS_ENDPOINT")
RDS_DB           = os.getenv("RDS_DB","appdb")
RDS_USER         = os.getenv("RDS_USER","appadmin")
SECRET_ARN       = os.getenv("SECRET_ARN")

s3  = boto3.client("s3")
ddb = boto3.resource("dynamodb").Table(DDB_TABLE)
secrets = boto3.client("secretsmanager")

def get_db_password():
    val = secrets.get_secret_value(SecretId=SECRET_ARN)
    return json.loads(val["SecretString"])["password"]

def pg_conn():
    pwd = get_db_password()
    return psycopg2.connect(host=RDS_ENDPOINT, dbname=RDS_DB, user=RDS_USER, password=pwd, connect_timeout=5)

def ensure_schema():
    with pg_conn() as conn, conn.cursor() as cur:
        cur.execute("""
        create table if not exists ingest_jobs(
          id uuid primary key,
          raw_key text not null,
          processed_key text,
          status text not null default 'PENDING',
          size_bytes bigint,
          content_type text,
          created_at timestamptz default now(),
          updated_at timestamptz default now()
        );
        """)
        conn.commit()

def process_once():
    resp = s3.list_objects_v2(Bucket=RAW_BUCKET, MaxKeys=10)
    for obj in resp.get("Contents", []):
        key = obj["Key"]
        if key.endswith("/"): continue
        asset_id  = str(uuid.uuid4())
        ctype,_   = mimetypes.guess_type(key)
        size      = int(obj.get("Size",0))
        with pg_conn() as conn, conn.cursor() as cur:
            cur.execute("insert into ingest_jobs(id, raw_key, size_bytes, content_type) values (%s,%s,%s,%s)",
                        (asset_id, key, size, ctype or "application/octet-stream"))
            conn.commit()
        dst = f"processed/{os.path.basename(key)}"
        s3.copy_object(Bucket=PROCESSED_BUCKET, CopySource={"Bucket": RAW_BUCKET, "Key": key}, Key=dst)
        with pg_conn() as conn, conn.cursor() as cur:
            cur.execute("update ingest_jobs set processed_key=%s, status='DONE', updated_at=now() where id=%s",
                        (dst, asset_id))
            conn.commit()
        today = time.strftime("%Y-%m-%d", time.gmtime())
        ddb.put_item(Item={
            "assetId": asset_id, "ingestDate": today,
            "bucket": RAW_BUCKET, "rawKey": key, "processedKey": dst,
            "sizeBytes": size, "contentType": ctype or "application/octet-stream", "status": "DONE"
        })
    return True

def main():
    ensure_schema()
    process_once()

if __name__ == "__main__":
    main()
PY

    cat >/etc/systemd/system/media-worker.service <<'SVC'
[Unit]
Description=Media Intake Worker
After=network-online.target

[Service]
Type=oneshot
Environment=RAW_BUCKET=${var.raw_bucket_name}
Environment=PROCESSED_BUCKET=${var.processed_bucket_name}
Environment=DDB_TABLE=${var.ddb_table_name}
Environment=RDS_ENDPOINT=${var.aurora_endpoint}
Environment=RDS_DB=${var.aurora_db_name}
Environment=RDS_USER=${var.aurora_db_user}
Environment=SECRET_ARN=${var.aurora_secret_arn}
ExecStart=/usr/bin/python3 /opt/worker.py

[Install]
WantedBy=multi-user.target
SVC

    systemctl daemon-reload
    systemctl enable --now media-worker.service
  EOF

  tags = merge(var.tags, { Name = "${var.project_prefix}-worker" })
}

