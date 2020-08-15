import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SNSEvent;
import com.amazonaws.services.lambda.runtime.events.SNSEvent.SNSRecord;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.AmazonS3ClientBuilder;

import java.util.List;

import static java.util.UUID.randomUUID;

public class Handler implements RequestHandler<SNSEvent, String> {
    @Override
    public String handleRequest(SNSEvent snsEvent, Context context) {
        String bucketName = System.getenv("BUCKET_NAME");
        String region = System.getenv("REGION");
        AmazonS3 s3 = AmazonS3ClientBuilder.standard().withRegion(region).build();
        List<SNSRecord> records = snsEvent.getRecords();
        System.out.println("Received " + records.size() + " records");
        records.forEach(snsRecord -> {
            String message = snsRecord.getSNS().getMessage();
            long timestamp = snsRecord.getSNS().getTimestamp().getMillis();
            s3.putObject(bucketName, timestamp + "-" + randomUUID().toString() + ".txt", message);
        });
        return "200 OK";
    }
}