import com.google.gson.Gson;
import lombok.Value;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.impl.SimpleLogger;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.DeleteMessageRequest;
import software.amazon.awssdk.services.sqs.model.Message;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageRequest;
import software.amazon.awssdk.services.sqs.model.SqsException;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;

@Slf4j
public class Main {
    @Value
    private static class Metadata {
        String ContainerID;
    }

    public static void main(String[] args) {
        String queueUrl = System.getenv("QUEUE_URL");
        String metadataFile = System.getenv("ECS_CONTAINER_METADATA_FILE");
        Gson gson = new Gson();
        String metadataFileContent;
        try {
         metadataFileContent = new String(Files.readAllBytes(Paths.get(metadataFile)), StandardCharsets.UTF_8);
        } catch (IOException e) {
            log.error("Unable to read file", e);
            throw new RuntimeException(e);
        }
        SqsClient client = SqsClient.create();
        String containerId = gson.fromJson(metadataFileContent, Metadata.class).getContainerID();
        while (true) {
            try {
                ReceiveMessageRequest request = ReceiveMessageRequest.builder()
                        .queueUrl(queueUrl)
                        .build();
                log.info("Checking for messages");
                List<Message> messages = client.receiveMessage(request).messages();
                log.info("Number of messages received: {}", messages.size());
                messages.forEach(message -> {
                    log.info("Node {} received message: {}", containerId, message.body());
                    DeleteMessageRequest deleteRequest = DeleteMessageRequest.builder()
                            .queueUrl(queueUrl)
                            .receiptHandle(message.receiptHandle())
                            .build();
                    client.deleteMessage(deleteRequest);
                });
            } catch (SqsException e) {
                log.error("SQS error", e);
            }
        }
    }
}
