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
import javafx.collections.FXCollections;
import javafx.collections.ObservableList;
import javafx.scene.control.ListView;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.StringReader;
import java.io.FileReader;
import java.io.FileWriter;

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
import java.nio.file.Path;
import java.io.FileOutputStream;
import java.util.Properties;

public class AppController {

    private Map<FontAwesomeIconView, RotateTransition> rotateTransitionMap = new HashMap<>();

    @FXML
    private Button buttonCheckDependencies;

    @FXML
    private Button refreshResultsButton;

    @FXML
    private Button downloadResultsButton;

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
    private FontAwesomeIconView downloadResultsButtonIcon;

    @FXML
    private FontAwesomeIconView runTestButtonIcon;

    @FXML
    private FontAwesomeIconView stopTestButtonIcon;

    @FXML
    private FontAwesomeIconView openGrafanaButtonIcon;

    @FXML
    private FontAwesomeIconView deleteResourcesButtonIcon;

    @FXML
    private TextField simulationPathTextField;

    @FXML
    private TextField simulationNameTextField;

    @FXML
    private ComboBox<String> awsProfileComboBox;

    @FXML
    private ComboBox<String> awsRegionComboBox;

    @FXML
    private Slider numberOfLoadAgentsSlider;

    @FXML
    private ComboBox<String> agentCpuComboBox;

    @FXML
    private ComboBox<String> agentMemoryComboBox;

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

        agentCpuComboBox.getItems().addAll("512", "1024", "2048", "4096", "8192", "16384");
        agentMemoryComboBox.getItems().clear();
        agentCpuComboBox.valueProperty().addListener((observable, oldValue, newValue) -> {
            agentMemoryComboBox.getItems().clear();
            switch (newValue) {
                case "512":
                    agentMemoryComboBox.getItems().addAll("1024", "2048", "3072", "4096");
                    break;
                case "1024":
                    agentMemoryComboBox.getItems().addAll("2048", "3072", "4096", "5120", "6144", "7168", "8192");
                    break;
                case "2048":
                    for (int i = 4; i <= 16; i++) {
                        agentMemoryComboBox.getItems().add(i * 1024 + "");
                    }
                    break;
                case "4096":
                    for (int i = 8; i <= 30; i++) {
                        agentMemoryComboBox.getItems().add(i * 1024 + "");
                    }
                    break;
                case "8192":
                    for (int i = 16; i <= 60; i += 4) {
                        agentMemoryComboBox.getItems().add(i * 1024 + "");
                    }
                    break;
                case "16384":
                    for (int i = 32; i <= 120; i += 8) {
                        agentMemoryComboBox.getItems().add(i * 1024 + "");
                    }
                    break;
            }
            agentMemoryComboBox.setValue(agentMemoryComboBox.getItems().get(0));
        });
        agentCpuComboBox.setValue("512"); // This will trigger the listener and set the initial memory options

        String homeDirectory = System.getProperty("user.home");
        String filePath = Paths.get(homeDirectory, ".aws", "credentials").toString();
        Set<String> sections = getSectionNames(filePath);
        sections.add("default");
        for (String section : sections) {
            awsProfileComboBox.getItems().add(section);
        }

        awsRegionComboBox.getItems().addAll("us-east-1", "us-east-2", "us-west-1", "us-west-2", "eu-central-1",
                "eu-west-1", "eu-west-2", "eu-west-3", "eu-north-1", "ap-northeast-1", "ap-northeast-2",
                "ap-northeast-3", "ap-southeast-1", "ap-southeast-2", "ap-south-1", "sa-east-1", "ca-central-1");

        // set default values
        // load state file from root
        Path stateFilePath = Paths.get(homeDirectory, "cloud-trash-state.properties");
        if (stateFilePath.toFile().exists()) {
            Properties properties = new Properties();

            try (FileInputStream in = new FileInputStream(stateFilePath.toFile().getAbsolutePath())) {
                properties.load(in);

                simulationNameTextField.setText(properties.getProperty("simulationName", ""));
                simulationPathTextField.setText(properties.getProperty("simulationPath", ""));
                numberOfLoadAgentsSlider
                        .setValue(Double.parseDouble(properties.getProperty("numberOfLoadAgents", "0")));

                // Parse CPU and Memory values as Integers
                try {
                    String agentCpu = properties.getProperty("agentCpu", "512");
                    agentCpuComboBox.setValue(agentCpu);
                } catch (NumberFormatException e) {
                    agentCpuComboBox.setValue("512"); // Default value if parsing fails
                }

                try {
                    String agentMemory = properties.getProperty("agentMemory", "1024");
                    agentMemoryComboBox.setValue(agentMemory);
                } catch (NumberFormatException e) {
                    agentMemoryComboBox.setValue("1024"); // Default value if parsing fails
                }

                awsProfileComboBox.setValue(properties.getProperty("awsProfile", "default"));
                awsRegionComboBox.setValue(properties.getProperty("awsRegion", "us-east-1"));
                envvars.setText(properties.getProperty("envvars", ""));

                System.out.println("State loaded from: " + stateFilePath);
            } catch (IOException e) {
                e.printStackTrace();
            }
            envvars.setText(properties.getProperty("envvars", ""));
        }

        logOutput.setText("Initialization done.\n");
    }

    @FXML
    private void handleButtonCheckDependenciesClick() {
        String scriptPath = "../scripts/check-dependencies.sh";
        Task<ShellScriptResult> task = ShellScript.runShellScript(scriptPath, logOutput);

        new Thread(task).start();
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

        writeProperties();

        String scriptPath = "../scripts/run-test.sh";
        logOutput.setText("");

        Map<String, String> env = new HashMap<>();
        env.put("AWS_PROFILE", awsProfileComboBox.getValue());
        env.put("AWS_REGION", awsRegionComboBox.getValue());
        env.put("SLAVE_COUNT", numberOfAgentsInfo.getText());
        env.put("SLAVE_CPU", agentCpuComboBox.getValue().toString());
        env.put("SLAVE_MEMORY", agentMemoryComboBox.getValue().toString());
        env.put("APP_NAME", simulationNameTextField.getText());
        env.put("ENV_VARS", envvars.getText().replace("\n", "###"));

        Task<ShellScriptResult> task = ShellScript.runShellScript(scriptPath, logOutput, env);
        task.setOnSucceeded(event -> {
            stopSpinnerAnimation(runTestButtonIcon);
            runTestButtonIcon.setGlyphName("PLAY");
            runTestButton.setDisable(false);
            handleButtonRefreshResultsClick();

            stopTestButtonIcon.setGlyphName("POWER_OFF");
            stopSpinnerAnimation(stopTestButtonIcon);
            stopTestButton.setDisable(true);
        });

        task.setOnFailed(event -> {
            stopSpinnerAnimation(runTestButtonIcon);
            runTestButtonIcon.setGlyphName("PLAY");
            runTestButton.setDisable(false);
            handleButtonRefreshResultsClick();

            stopTestButtonIcon.setGlyphName("POWER_OFF");
            stopSpinnerAnimation(stopTestButtonIcon);
            stopTestButton.setDisable(true);
        });

        task.setOnRunning(event -> {
            ChangeListener<String> listener = new ChangeListener<String>() {
                @Override
                public void changed(ObservableValue<? extends String> observable, String oldValue, String newValue) {
                    if (logOutput.getText().contains("Current task status: PENDING")
                            || logOutput.getText().contains("Current task status: RUNNING")) {
                        stopTestButton.setDisable(false);
                        logOutput.textProperty().removeListener(this);
                    }
                }
            };

            logOutput.textProperty().addListener(listener);
        });

        new Thread(task).start();
    }

    @FXML
    private void handleButtonStopTestClick() {
        stopTestButtonIcon.setGlyphName("SPINNER");
        startSpinnerAnimation(stopTestButtonIcon);
        stopTestButton.setDisable(true);

        String scriptPath = "../scripts/stop-test-all.sh";
        Task<ShellScriptResult> task = ShellScript.runShellScript(scriptPath, logOutput);

        new Thread(task).start();
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

        new Thread(task).start();
    }

    @FXML
    private void handleButtonDeleteResourcesClick() {
        deleteResourcesButton.setDisable(true);
        deleteResourcesButtonIcon.setGlyphName("SPINNER");
        startSpinnerAnimation(deleteResourcesButtonIcon);
        String scriptPath = "../scripts/delete-all-resources-approved.sh";
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

        new Thread(task).start();
    }

    @FXML
    private void resultsClicked() {
        Map<String, String> env = new HashMap<>();

        try {
            env.put("FILE_LOCATION", results.getSelectionModel().getSelectedItem().split(" ")[2]);
        } catch (Exception e) {
            logOutput.setText("A result to download must be selected.\n");
            return;
        }

        downloadResultsButtonIcon.setGlyphName("SPINNER");
        startSpinnerAnimation(downloadResultsButtonIcon);
        downloadResultsButton.setDisable(true);

        String scriptPath = "../scripts/download.sh";
        Task<ShellScriptResult> task = ShellScript.runShellScript(scriptPath, logOutput, env);

        task.setOnSucceeded(event -> {
            downloadResultsButtonIcon.setGlyphName("SAVE");
            stopSpinnerAnimation(downloadResultsButtonIcon);
            downloadResultsButton.setDisable(false);
        });

        task.setOnFailed(event -> {
            downloadResultsButtonIcon.setGlyphName("SAVE");
            stopSpinnerAnimation(downloadResultsButtonIcon);
            downloadResultsButton.setDisable(false);
        });

        new Thread(task).start();
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

    public void writeProperties() {
        // Properties object to hold key-value pairs
        Properties properties = new Properties();

        // Set the properties from the GUI components
        properties.setProperty("simulationName", simulationNameTextField.getText());
        properties.setProperty("simulationPath", simulationPathTextField.getText());
        properties.setProperty("numberOfLoadAgents", String.valueOf((int) numberOfLoadAgentsSlider.getValue()));
        properties.setProperty("agentCpu", agentCpuComboBox.getValue());
        properties.setProperty("agentMemory", agentMemoryComboBox.getValue());
        properties.setProperty("awsProfile", awsProfileComboBox.getValue());
        properties.setProperty("awsRegion", awsRegionComboBox.getValue());
        properties.setProperty("envvars", envvars.getText());

        // File path for saving the properties
        String homeDirectory = System.getProperty("user.home");
        String stateFilePath = homeDirectory + "/cloud-trash-state.properties"; // Using .properties file extension

        // Save properties to a file
        try (FileOutputStream out = new FileOutputStream(stateFilePath)) {
            properties.store(out, "Simulation Configuration");
            System.out.println("State saved to: " + stateFilePath);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}