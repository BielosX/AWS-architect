import lombok.extern.slf4j.Slf4j;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.PublishRequest;
import software.amazon.awssdk.services.sns.model.SnsException;

@Slf4j
public class Main {
    public static void main(String[] args) {
        String topicArn = System.getenv("TOPIC_ARN");
        SnsClient client = SnsClient.create();
        while (true) {
            PublishRequest request = PublishRequest.builder()
                    .message("Test message")
                    .topicArn(topicArn)
                    .build();
            log.info("Publishing message");
            try {
                client.publish(request);
                Thread.sleep(2000 * 60);
            } catch (SnsException e) {
                log.error("Unable to publish", e);
            } catch (InterruptedException e) {
                log.error("Sleep exception", e);
            }
        }
    }
}
