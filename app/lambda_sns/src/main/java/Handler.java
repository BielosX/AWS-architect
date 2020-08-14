import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.SNSEvent;

public class Handler implements RequestHandler<SNSEvent, String> {
    @Override
    public String handleRequest(SNSEvent snsEvent, Context context) {
        return "200 OK";
    }
}
