import { S3Client, CopyObjectCommand } from '@aws-sdk/client-s3';

const s3 = new S3Client({});
const debug = process.env.DEBUG === 'true';

export const handler = async (event) => {
  if (debug) console.log('Received event:', JSON.stringify(event, null, 2));

  for (const record of event.Records) {
    try {
      const body = JSON.parse(record.body);
      if (!body?.Records?.length) {
        if (debug) console.log("No valid S3 event records found.");
        continue;
      }
      const s3Event = body.Records[0];

      if (!s3Event) {
        if (debug) console.log('No S3 event found in message. Skipping.');
        continue;
      }

      const srcBucket = s3Event.s3.bucket.name;
      const srcKey = decodeURIComponent(s3Event.s3.object.key.replace(/\+/g, ' '));
      const destBucket = process.env.BUCKET_NAME;

      const copyParams = {
        Bucket: destBucket,
        CopySource: `${srcBucket}/${srcKey}`,
        Key: srcKey,
      };

      if (debug) {
        console.log(`Copying from: ${srcBucket}/${srcKey}`);
        console.log(`To: ${destBucket}/${srcKey}`);
      }

      await s3.send(new CopyObjectCommand(copyParams));

      if (debug) console.log(`Copied successfully: ${srcKey}`);
    } catch (err) {
      console.error('Error processing record:', err);
    }
  }
};
