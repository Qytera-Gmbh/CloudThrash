import javafx.fxml.FXML;
import javafx.scene.control.Button;
import javafx.scene.control.TextArea;
import javafx.scene.control.ListView;
import javafx.scene.control.TreeTableView;
import javafx.scene.control.Label;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.text.SimpleDateFormat;
import java.util.Date;

public class AppController {

    @FXML
    private Button buttonCheckDependencies;

    @FXML
    private TextArea logOutput;

    @FXML
    private ListView results;

    @FXML
    private TextArea envvars;

    @FXML
    public void initialize() {

    }

    @FXML
    private void handleButtonCheckDependenciesClick() {
        String scriptPath = "../scripts/check-dependencies.sh";
        int exitCode = runShellScript(scriptPath);
    }

    public int runShellScript(String scriptPath) {
        String gitBashPath = "C:/Program Files/Git/bin/bash.exe";

        logOutput.appendText(getTimestamp() + "Running " + scriptPath + "\n");

        ProcessBuilder processBuilder = new ProcessBuilder(gitBashPath, "-c", scriptPath);

        int exitCode = -1;

        try {
            Process process = processBuilder.start();

            BufferedReader stdoutReader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = stdoutReader.readLine()) != null) {
                logOutput.appendText(getTimestamp() + line + "\n");
            }

            BufferedReader stderrReader = new BufferedReader(new InputStreamReader(process.getErrorStream()));
            while ((line = stderrReader.readLine()) != null) {
                logOutput.appendText(getTimestamp() + ">> " + line + "\n");
            }

            exitCode = process.waitFor();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
            logOutput.appendText(getTimestamp() + ">> " + e.getMessage() + "\n");
        }

        logOutput.appendText(getTimestamp() + "Exit code: " + exitCode + "\n");
        logOutput.appendText(getTimestamp() + "-------------------\n");

        logOutput.setScrollTop(Double.MAX_VALUE);

        return exitCode;
    }

    private String getTimestamp() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        return "[" + sdf.format(new Date()) + "] ";
    }
}
