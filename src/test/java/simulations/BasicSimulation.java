package simulations;

import io.gatling.javaapi.core.*;
import io.gatling.javaapi.http.*;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

public class BasicSimulation extends Simulation {

    HttpProtocolBuilder httpProtocol = http.baseUrl("https://example.com").acceptHeader("application/json");

    ScenarioBuilder scn = scenario("BasicSimulation").exec(http("request_1").get("/")).pause(5);

    {
        setUp(scn.injectOpen(atOnceUsers(10)).protocols(httpProtocol));
    }
}
