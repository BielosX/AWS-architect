import com.amazonaws.services.simplesystemsmanagement.AWSSimpleSystemsManagement;
import com.amazonaws.services.simplesystemsmanagement.AWSSimpleSystemsManagementClientBuilder;
import com.amazonaws.services.simplesystemsmanagement.model.GetParameterRequest;
import lombok.Value;

@Value
public class AwsProperties implements PropertiesProvider {
    String prefix;
    AWSSimpleSystemsManagement ssm = AWSSimpleSystemsManagementClientBuilder.defaultClient();

    public String getString(String name) {
        GetParameterRequest request = new GetParameterRequest();
        request.setName(prefix + name);
        request.setWithDecryption(true);
        return ssm.getParameter(request).getParameter().getValue();
    }
}
