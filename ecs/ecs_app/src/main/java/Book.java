import lombok.Value;

import java.util.UUID;

@Value
public class Book {
    UUID id;
    String firstName;
    String lastName;
}
