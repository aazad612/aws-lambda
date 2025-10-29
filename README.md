# aws-lambda
What happens:
A file lands in S3 raw.
Notifier logs the arrival (DDB RECEIVED).
Processor copies it to processed/, marks DDB PROCESSED, and upserts job status into Aurora (no VPC needed thanks to RDS Data API).
(Optional) EC2 worker can still process batches or do heavy lifting.


![plot](./media-intake.png)