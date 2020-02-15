import com.google.gson.Gson;
import lombok.Value;
import lombok.extern.slf4j.Slf4j;
import software.amazon.awssdk.services.sns.SnsClient;
import software.amazon.awssdk.services.sns.model.ConfirmSubscriptionRequest;
import software.amazon.awssdk.services.sns.model.SnsException;
import software.amazon.awssdk.services.sns.model.SubscribeRequest;
import spark.Spark;

@Slf4j
public class Main {
    public static void main(String[] args) {
        Spark.port(8080);
        String topicArn = System.getenv("TOPIC_ARN");
        String lbUrl = System.getenv("LB_URL");
        SnsClient client = SnsClient.create();
        Gson gson = new Gson();
        Spark.get("/health", (req, res) -> {
            res.status(200);
            return "Healthy";
        });
        Spark.post("/subscribe", (req, res) -> {
            SubscribeRequest subscribeRequest = SubscribeRequest.builder()
                    .topicArn(topicArn)
                    .endpoint(lbUrl + "/notify")
                    .protocol("http")
                    .build();
            try {
                client.subscribe(subscribeRequest);
            } catch (SnsException e) {
                log.error("Unable to subscribe", e);
            }
            return "OK";
        });
        Spark.post("/notify", (req,res) -> {
            String type = req.headers("x-amz-sns-message-type");
            if (type.equals("SubscriptionConfirmation")) {
                SubscriptionConfirmation confirmation = gson.fromJson(req.body(), SubscriptionConfirmation.class);
                ConfirmSubscriptionRequest request = ConfirmSubscriptionRequest.builder()
                        .token(confirmation.getToken())
                        .topicArn(confirmation.getTopicArn())
                        .build();
                client.confirmSubscription(request);
            }
            if (type.equals("Notification")) {
                Notification notification = gson.fromJson(req.body(), Notification.class);
                log.info("Received message: {}", notification.getMessage());
            }
            return "OK";
        });
    }

    @Value
    private static class Notification {
        String Message;
    }

    @Value
    private static class SubscriptionConfirmation {
        String Token;
        String TopicArn;
    }
}
