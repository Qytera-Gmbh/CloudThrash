import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.TextArea;
import javafx.scene.text.Text;
import javafx.scene.control.TextField;
import javafx.scene.control.ComboBox;
import javafx.scene.control.Slider;
import javafx.scene.control.Tooltip;
import de.jensd.fx.glyphs.fontawesome.FontAwesomeIconView;
import javafx.beans.value.ChangeListener;
import javafx.beans.value.ObservableValue;
import javafx.scene.control.ListView;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.io.FileReader;
import javafx.concurrent.Task;
import de.besessener.ShellScript;
import de.besessener.ShellScriptResult;
import de.jensd.fx.glyphs.fontawesome.FontAwesomeIcon;
import javafx.animation.RotateTransition;
import javafx.util.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.HashSet;
import java.util.regex.*;
import java.nio.file.Paths;

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
    private FontAwesomeIconView openGrafanaButtonIcon;

    @FXML
    private FontAwesomeIconView deleteResourcesButtonIcon;

    @FXML
    private TextField simulationPathTextField;

    @FXML
    private TextField simulationNameTextField;

    @FXML
    private ComboBox awsProfileComboBox;

    @FXML
    private ComboBox awsRegionComboBox;

    @FXML
    private Slider numberOfLoadAgentsSlider;

    @FXML
    private Slider agentCpuSlider;

    @FXML
    private Slider agentMemorySlider;

    @FXML
    private FontAwesomeIconView simulationPathInfoIcon;

    @FXML
    private FontAwesomeIconView simulationNameInfoIcon;

    @FXML
    private FontAwesomeIconView awsProfileInfoIcon;

    @FXML
    private FontAwesomeIconView awsRegionInfoIcon;

    @FXML
    private Text numberOfAgentsInfo;

    @FXML
    private Text agentsCpuInfo;

    @FXML
    private Text agentsMemoryInfo;

    @FXML
    private FontAwesomeIconView envvarInfoIcon;

    @FXML
    public void initialize() {
        // tooltips
        Tooltip.install(simulationPathInfoIcon,
                new Tooltip("Give a complete path, Git URL or leave it to 'demo' for a simple URL test."));
        Tooltip.install(simulationNameInfoIcon, new Tooltip(
                "Give a name to your simulation that will be used for AWS resources and Grafana Dashboards."));
        Tooltip.install(awsProfileInfoIcon, new Tooltip("A AWS profile name from your ~/.aws/* files."));
        Tooltip.install(awsRegionInfoIcon, new Tooltip("A AWS region name, like 'us-east-1' or 'eu-central-1'."));
        Tooltip.install(envvarInfoIcon, new Tooltip(
                "Set environment variables for the simulation. Example: 'VUS' for the number of virtual users, 'DURATION' for the test duration and 'URL' for the target URL."));

        // listeners
        numberOfLoadAgentsSlider.valueProperty().addListener(new ChangeListener<Number>() {
            @Override
            public void changed(ObservableValue<? extends Number> observable, Number oldValue, Number newValue) {
                int roundedValue = (int) Math.round(newValue.doubleValue());
                numberOfAgentsInfo.setText(String.valueOf(roundedValue));
            }
        });

        agentCpuSlider.valueProperty().addListener(new ChangeListener<Number>() {
            @Override
            public void changed(ObservableValue<? extends Number> observable, Number oldValue, Number newValue) {
                int roundedValue = (int) Math.round(newValue.doubleValue());
                agentsCpuInfo.setText(String.valueOf(roundedValue));
            }
        });

        agentMemorySlider.valueProperty().addListener(new ChangeListener<Number>() {
            @Override
            public void changed(ObservableValue<? extends Number> observable, Number oldValue, Number newValue) {
                int roundedValue = (int) Math.round(newValue.doubleValue());
                agentsMemoryInfo.setText(String.valueOf(roundedValue));
            }
        });

        // set default values
        String homeDirectory = System.getProperty("user.home");
        String filePath = Paths.get(homeDirectory, ".aws", "credentials").toString();
        Set<String> sections = getSectionNames(filePath);
        sections.add("default");
        for (String section : sections) {
            awsProfileComboBox.getItems().add(section);
        }
        awsProfileComboBox.setValue("default");

        awsRegionComboBox.getItems().addAll("us-east-1", "us-east-2", "us-west-1", "us-west-2", "eu-central-1",
                "eu-west-1", "eu-west-2", "eu-west-3", "eu-north-1", "ap-northeast-1", "ap-northeast-2",
                "ap-northeast-3", "ap-southeast-1", "ap-southeast-2", "ap-south-1", "sa-east-1", "ca-central-1");
        awsRegionComboBox.setValue("us-east-1");

        logOutput.setText("Initialization done.\n");
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
        Map<String, String> env = Map.of("AWS_PROFILE", awsProfileComboBox.getValue().toString(), "AWS_REGION",
                awsRegionComboBox.getValue().toString(), "SLAVE_COUNT", numberOfAgentsInfo.getText(), "SLAVE_CPU",
                agentsCpuInfo.getText(), "SLAVE_MEMORY", agentsMemoryInfo.getText(), "APP_NAME",
                simulationNameTextField.getText());
        for (String envvar : envvars.getText().split("\n")) {
            String[] parts = envvar.split("=");
            if (parts.length == 2 && !parts[0].startsWith("#")) {
                env.put(parts[0], parts[1]);
            }
        }
        Task<ShellScriptResult> task = ShellScript.runShellScript(scriptPath, logOutput, env);
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
        openGrafanaButton.setDisable(true);
        openGrafanaButtonIcon.setGlyphName("SPINNER");
        startSpinnerAnimation(openGrafanaButtonIcon);
        String scriptPath = "../scripts/open-grafana.sh";
        Task<ShellScriptResult> task = ShellScript.runShellScript(scriptPath, logOutput);

        task.setOnSucceeded(event -> {
            stopSpinnerAnimation(openGrafanaButtonIcon);
            openGrafanaButtonIcon.setGlyphName("TACHOMETER");
            openGrafanaButton.setDisable(false);
        });

        task.setOnFailed(event -> {
            stopSpinnerAnimation(openGrafanaButtonIcon);
            openGrafanaButtonIcon.setGlyphName("TACHOMETER");
            openGrafanaButton.setDisable(false);
        });
    }

    @FXML
    private void handleButtonDeleteResourcesClick() {
        deleteResourcesButton.setDisable(true);
        deleteResourcesButtonIcon.setGlyphName("SPINNER");
        startSpinnerAnimation(deleteResourcesButtonIcon);
        String scriptPath = "../scripts/delete-all-resources.sh -y";
        Task<ShellScriptResult> task = ShellScript.runShellScript(scriptPath, logOutput);

        task.setOnSucceeded(event -> {
            stopSpinnerAnimation(deleteResourcesButtonIcon);
            deleteResourcesButtonIcon.setGlyphName("TRASH");
            deleteResourcesButton.setDisable(false);
        });

        task.setOnFailed(event -> {
            stopSpinnerAnimation(deleteResourcesButtonIcon);
            deleteResourcesButtonIcon.setGlyphName("TRASH");
            deleteResourcesButton.setDisable(false);
        });
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

    // Method to get section names from INI file
    public static Set<String> getSectionNames(String filePath) {
        Set<String> sectionNames = new HashSet<>();
        Pattern sectionPattern = Pattern.compile("\\[([^]]+)]");

        try {
            try (BufferedReader reader = new BufferedReader(new FileReader(filePath))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    Matcher matcher = sectionPattern.matcher(line);
                    if (matcher.find()) {
                        // Add the section name without the brackets
                        sectionNames.add(matcher.group(1));
                    }
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        return sectionNames;
    }
}
