import com.google.gson.Gson;
import com.zaxxer.hikari.HikariDataSource;
import org.jooq.DSLContext;
import org.jooq.impl.DSL;
import spark.Spark;

import java.util.UUID;

import static org.jooq.SQLDialect.POSTGRES;
import static org.jooq.codegen.ecs.app.tables.Books.BOOKS;

public class Main {
    public static void main(String[] args) {
        HikariDataSource dataSource = new HikariDataSource();
        dataSource.setDriverClassName("org.postgresql.Driver");
        dataSource.setJdbcUrl("jdbc:postgresql://db/appdb");
        dataSource.setUsername("root");
        dataSource.setPassword("root");
        DSLContext context = DSL.using(dataSource, POSTGRES);
        Gson gson = new Gson();

        Spark.get("/books", (req, res) -> gson.toJson(context.selectFrom(BOOKS).fetchInto(Book.class)));
        Spark.post("/books", (req,res) -> {
            BookRequest request = gson.fromJson(req.body(), BookRequest.class);
            Book book = new Book(UUID.randomUUID(), request.getFirstName(), request.getLastName());
            context.insertInto(BOOKS)
                    .set(BOOKS.ID, book.getId())
                    .set(BOOKS.FIRST_NAME, book.getFirstName())
                    .set(BOOKS.LAST_NAME, book.getLastName())
                    .execute();
            return gson.toJson(book);
        });
    }
}
