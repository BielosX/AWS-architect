import com.google.gson.Gson;
import com.zaxxer.hikari.HikariDataSource;
import org.jooq.DSLContext;
import org.jooq.codegen.ecs.app.tables.records.BooksRecord;
import org.jooq.impl.DSL;
import spark.Spark;

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
            BooksRecord record = context.newRecord(BOOKS);
            record.setFirstName(request.getFirstName());
            record.setLastName(record.getLastName());
            record.store();
            return new Book(record.getId(), record.getFirstName(), record.getLastName());
        });
    }
}
