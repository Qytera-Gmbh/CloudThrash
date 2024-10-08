package simulations;

import io.gatling.javaapi.core.*;
import io.gatling.javaapi.http.*;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

import java.util.HashMap;
import java.util.Map;
import java.time.Duration;

public class BasicSimulation extends Simulation {

        ScenarioBuilder scn = scenario("Scenario 1")
                        .forever()
                        .on(exec(http("request_1").get("/")).pause(Duration.ofMillis(250)));

        {
                String env_vars = System.getenv("ENV_VARS") != null ? System.getenv("ENV_VARS") : "";
                Map<String, String> env_vars_map = new HashMap<>();
                for (String env_var : env_vars.split("###")) {
                        String[] parts = env_var.split("=");
                        if (parts.length == 2) {
                                env_vars_map.put(parts[0], parts[1]);
                        }
                }

                System.out.println("Environment variables:");
                for (Map.Entry<String, String> entry : env_vars_map.entrySet()) {
                        System.out.println(entry.getKey() + " = " + entry.getValue());
                }

                int vus = env_vars_map.containsKey("VUS") ? Integer.parseInt(env_vars_map.get("VUS")) : 20;
                int rampUpDuration = env_vars_map.containsKey("RAMP_UP_DURATION")
                                ? Integer.parseInt(env_vars_map.get("RAMP_UP_DURATION"))
                                : 30;
                int duration = env_vars_map.containsKey("DURATION") ? Integer.parseInt(env_vars_map.get("DURATION"))
                                : 30;

                HttpProtocolBuilder httpProtocol = http
                                .baseUrl(env_vars_map.containsKey("URL") ? env_vars_map.get("URL")
                                                : "https://www.demoblaze.com/")
                                .acceptHeader("application/json")
                                .disableCaching();

                setUp(scn.injectOpen(
                                nothingFor(Duration.ofSeconds(10)),
                                rampUsers(vus).during(Duration.ofSeconds(rampUpDuration)),
                                nothingFor(Duration.ofSeconds(duration)))).protocols(httpProtocol)
                                .maxDuration(Duration.ofSeconds(30 + rampUpDuration + duration)).assertions(
                                                global().responseTime().percentile2().lt(100),
                                                global().successfulRequests().percent().gt(95.0));
        }
}
