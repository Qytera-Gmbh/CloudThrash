import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.TextArea;
import javafx.scene.control.ListView;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.StringReader;
import javafx.concurrent.Task;
import de.besessener.ShellScript;
import de.besessener.ShellScriptResult;
import de.jensd.fx.glyphs.fontawesome.FontAwesomeIcon;
import de.jensd.fx.glyphs.fontawesome.FontAwesomeIconView;
import javafx.animation.RotateTransition;
import javafx.util.Duration;
import java.util.HashMap;
import java.util.Map;

public class AppController {

    private Map<FontAwesomeIconView, RotateTransition> rotateTransitionMap = new HashMap<>();

    @FXML
    private Button buttonCheckDependencies;

    @FXML
    private Button refreshResultsButton;

    @FXML
    private Button runTestButton;

    @FXML
    private Button stopTestButton;

    @FXML
    private Button openGrafanaButton;

    @FXML
    private Button deleteResourcesButton;

    @FXML
    private TextArea logOutput;

    @FXML
    private ListView<String> results;

    @FXML
    private TextArea envvars;

    @FXML
    private FontAwesomeIconView refreshButtonIcon;

    @FXML
    private FontAwesomeIconView runTestButtonIcon;

    @FXML
    public void initialize() {
        // Initialization code if needed
    }

    @FXML
    private void handleButtonCheckDependenciesClick() {
        String scriptPath = "../scripts/check-dependencies.sh";
        ShellScript.runShellScript(scriptPath, logOutput);
    }

    @FXML
    private void handleButtonRefreshResultsClick() {
        refreshResultsButton.setDisable(true);
        startSpinnerAnimation(refreshButtonIcon);
        String scriptPath = "../scripts/list-results.sh";
        Task<ShellScriptResult> task = ShellScript.runShellScript(scriptPath, logOutput);

        task.setOnSucceeded(event -> {
            ShellScriptResult result = task.getValue();
            BufferedReader reader = new BufferedReader(new StringReader(result.getLog()));

            String line;
            boolean foundResults = false;
            try {
                while ((line = reader.readLine()) != null) {
                    if (line.contains("Results:")) {
                        foundResults = true;
                        results.getItems().clear();
                        continue;
                    }

                    if (foundResults && (line.contains(" - success") || line.contains(" - failure"))) {
                        results.getItems().add(line);
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }

            stopSpinnerAnimation(refreshButtonIcon);
            refreshResultsButton.setDisable(false);
        });

        task.setOnFailed(event -> {
            Throwable exception = task.getException();
            logOutput.appendText("Script failed: " + exception.getMessage() + "\n");
            stopSpinnerAnimation(refreshButtonIcon);
            refreshResultsButton.setDisable(false);
        });

        new Thread(task).start();
    }

    @FXML
    private void handleButtonRunTestClick() {
        runTestButton.setDisable(true);
        runTestButtonIcon.setGlyphName("SPINNER");
        startSpinnerAnimation(runTestButtonIcon);
        String scriptPath = "../scripts/run-test.sh";
        Task<ShellScriptResult> task = ShellScript.runShellScript(scriptPath, logOutput);
        task.setOnSucceeded(event -> {
            stopSpinnerAnimation(runTestButtonIcon);
            runTestButtonIcon.setGlyphName("PLAY");
            runTestButton.setDisable(false);
            handleButtonRefreshResultsClick();
        });

        task.setOnFailed(event -> {
            stopSpinnerAnimation(runTestButtonIcon);
            runTestButtonIcon.setGlyphName("PLAY");
            runTestButton.setDisable(false);
            handleButtonRefreshResultsClick();
        });
    }

    @FXML
    private void handleButtonStopTestClick() {
        String scriptPath = "../scripts/stop-test.sh";
        ShellScript.runShellScript(scriptPath, logOutput);
    }

    @FXML
    private void handleButtonOpenGrafanaClick() {
        String scriptPath = "../scripts/open-grafana.sh";
        ShellScript.runShellScript(scriptPath, logOutput);
    }

    @FXML
    private void handleButtonDeleteResourcesClick() {
        String scriptPath = "../scripts/delete-all-resources.sh";
        ShellScript.runShellScript(scriptPath, logOutput);
    }

    private void startSpinnerAnimation(FontAwesomeIconView icon) {
        RotateTransition rotateTransition = new RotateTransition(Duration.millis(1000), icon);
        rotateTransition.setByAngle(360);
        rotateTransition.setCycleCount(RotateTransition.INDEFINITE);
        rotateTransition.play();

        rotateTransitionMap.put(icon, rotateTransition);
    }

    private void stopSpinnerAnimation(FontAwesomeIconView icon) {
        RotateTransition rotateTransition = rotateTransitionMap.get(icon);
        if (rotateTransition != null) {
            rotateTransition.stop();
            icon.setRotate(0);

            rotateTransitionMap.remove(icon);
        }
    }
}
