import com.google.gson.Gson;
import lombok.Value;
import redis.clients.jedis.Jedis;

import java.util.Map;
import java.util.UUID;

import static spark.Spark.*;

public class Main {
    @Value
    private static class RedisConfig {
        int redisPort;
        String redisAddr;
    }

    @Value
    private static class User {
        String firstName;
        String lastName;
    }

    @Value
    private static class UserView {
        UUID id;
        String firstName;
        String lastName;
    }

    public static void main(String[] args) {
        Gson gson = new Gson();
        String redisAddr = System.getenv("REDIS_ADDR");
        int redisPort = Integer.parseInt(System.getenv("REDIS_PORT"));
        RedisConfig config = new RedisConfig(redisPort, redisAddr);
        int appPort = Integer.parseInt(System.getenv("PORT"));
        port(appPort);
        Jedis jedis = new Jedis(redisAddr, redisPort);
        get("/conf", (req, res) -> gson.toJson(config));
        post("/users", (req,res) -> {
            UUID id = UUID.randomUUID();
            User user = gson.fromJson(req.body(), User.class);
            jedis.hset(id.toString(), "firstName", user.getFirstName());
            jedis.hset(id.toString(), "lastName", user.getLastName());
            return gson.toJson(new UserView(id, user.getFirstName(), user.getLastName()));
        });
        get("/users/:id", (req, res) -> {
            String idParam = req.params(":id");
            Map<String, String> obj = jedis.hgetAll(idParam);
            UUID id = UUID.fromString(req.params(":id"));
            return gson.toJson(new UserView(id, obj.get("firstName"), obj.get("lastName")));
        });
    }
}
