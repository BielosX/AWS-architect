import com.google.gson.Gson;
import lombok.Value;
import lombok.extern.slf4j.Slf4j;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;
import spark.Spark;

import java.util.UUID;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

@Slf4j
public class Main {

    @Value
    private static class Config {
        private final int sleepSeconds;
    }

    public static void main(String[] args) {
        Spark.port(8080);
        SqsClient client = SqsClient.create();
        String queueUrl = System.getenv("QUEUE_URL");
        Gson gson = new Gson();
        AtomicInteger waitTime = new AtomicInteger(30);
        Executor executor = Executors.newSingleThreadExecutor();
        String messageGroupId = UUID.randomUUID().toString();
        executor.execute(() -> {
            int deduplicationId = 0;
            while (true) {
                SendMessageRequest request = SendMessageRequest.builder()
                        .messageBody("Hello World!")
                        .queueUrl(queueUrl)
                        .messageGroupId(messageGroupId)
                        .messageDeduplicationId(String.valueOf(deduplicationId))
                        .build();
                log.info("Sending message");
                client.sendMessage(request);
                deduplicationId++;
                log.info("Message sent");
                try {
                    log.info("Wait time: {}", waitTime.get());
                    Thread.sleep(waitTime.get() * 1000);
                } catch (InterruptedException e) {
                    log.error("Sleep failed", e);
                }
            }
        });
        Spark.post("/config", (req,res) -> {
            Config config = gson.fromJson(req.body(), Config.class);
            waitTime.set(config.getSleepSeconds());
            return "OK";
        });
    }
}
