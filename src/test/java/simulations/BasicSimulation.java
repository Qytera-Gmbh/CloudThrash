package simulations;

import io.gatling.javaapi.core.*;
import io.gatling.javaapi.http.*;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

public class BasicSimulation extends Simulation {

        HttpProtocolBuilder httpProtocol = http.baseUrl("https://example.com")
                        .acceptHeader("application/json")
                        .disableCaching(); // Disable caching to ensure all requests are logged

        ScenarioBuilder scn = scenario("BasicSimulation")
                        .forever()
                        .on(exec(http("request_1").get("/")).pause(10)); // Pause for 10 seconds between requests

        {
                setUp(scn.injectOpen(atOnceUsers(5)).protocols(httpProtocol)).maxDuration(30);
        }
}
