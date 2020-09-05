public class PropertiesProviderFactory {
    public static PropertiesProvider crate(String profile) {
        if (profile.equals("local")) {
            return new LocalProperties();
        }
        if (profile.equals("aws")) {
            return new AwsProperties("/ecs_app/");
        }
        throw new IllegalArgumentException("Profile should be either local or aws");
    }
}
