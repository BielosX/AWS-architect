import com.google.gson.Gson;
import com.zaxxer.hikari.HikariDataSource;
import org.jooq.DSLContext;
import org.jooq.impl.DSL;
import spark.Spark;

import static org.jooq.SQLDialect.POSTGRES;
import static org.jooq.codegen.ecs.app.tables.Books.BOOKS;

public class Main {
    public static void main(String[] args) {
        HikariDataSource dataSource = new HikariDataSource();
        dataSource.setJdbcUrl("jdbc:postgresql://localhost:5432/appdb");
        dataSource.setUsername("root");
        dataSource.setPassword("root");
        DSLContext context = DSL.using(dataSource, POSTGRES);
        Gson gson = new Gson();

        Spark.get("/books", (req, res) -> gson.toJson(context.selectFrom(BOOKS).fetchInto(Book.class)));
    }
}
