import lombok.SneakyThrows;
import org.apache.commons.configuration2.PropertiesConfiguration;
import org.apache.commons.configuration2.builder.fluent.Configurations;

import java.io.File;

public class LocalProperties implements PropertiesProvider {
    PropertiesConfiguration config;

    @SneakyThrows
    public LocalProperties() {
        Configurations configs = new Configurations();
        File propertiesFile = new File("application.properties");
        config = configs.properties(propertiesFile);
    }

    public String getString(String key) {
        return config.getString(key);
    }
}
