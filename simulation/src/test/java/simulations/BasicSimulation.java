package simulations;

import io.gatling.javaapi.core.*;
import io.gatling.javaapi.http.*;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

import java.time.Duration;

public class BasicSimulation extends Simulation {

        HttpProtocolBuilder httpProtocol = http.baseUrl("https://www.demoblaze.com/")
                        .acceptHeader("application/json")
                        .disableCaching();

        ScenarioBuilder scn = scenario("BasicSimulation")
                        .forever()
                        .on(exec(http("request_1").get("/")).pause(Duration.ofMillis(250)));

        {
                setUp(scn.injectOpen(
                                nothingFor(Duration.ofSeconds(15)),
                                rampUsers(20).during(Duration.ofSeconds(30)),
                                nothingFor(Duration.ofMinutes(2)),
                                rampUsers(10).during(Duration.ofSeconds(30)))).protocols(httpProtocol)
                                .maxDuration(Duration.ofMinutes(5));
        }
}
